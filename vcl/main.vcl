
# Backends

# Static site backend
backend polyfill_static_site {
    .connect_timeout = 1s;
    .dynamic = true;
    .port = "80";
    .host = "polyfill.guim.co.uk.s3-website-eu-west-1.amazonaws.com";
    .first_byte_timeout = 15s;
    .max_connections = 200;
    .between_bytes_timeout = 10s;
    .share_key = "5f0Q6Z3xl3Shk3m6RQJyVs";

    .probe = {
        .request = "HEAD / HTTP/1.1"  "Host: polyfill.guim.co.uk.s3-website-eu-west-1.amazonaws.com" "Connection: close";
        .window = 5;
        .threshold = 1;
        .timeout = 2s;
        .initial = 5;
        .dummy = true;
      }
}

backend polyfill_service {
    .connect_timeout = 1s;
    .dynamic = true;
    .port = "80";
    .host = "cdn.polyfill.io";
    .first_byte_timeout = 15s;
    .max_connections = 200;
    .between_bytes_timeout = 10s;
    .share_key = "5f0Q6Z3xl3Shk3m6RQJyVs";

    .probe = {
        .request = "HEAD / HTTP/1.1"  "Host: cdn.polyfill.io" "Connection: close";
        .window = 5;
        .threshold = 1;
        .timeout = 2s;
        .initial = 5;
        .dummy = true;
      }
}

sub vcl_fetch {
#FASTLY fetch

  esi;

  # cache everything for 8 hours ignoring any cache headers
  set beresp.ttl = 8h;

  # use stale for a lot longer in case of fail, or our internet is down
  set beresp.stale_if_error = 48h;
}

sub vcl_recv {
#FASTLY recv

  # Default backend
  set req.backend = polyfill_static_site;

  # Path that goes to the polyfill backend /v2/
  if (req.url ~ "^/v2/.*") {
    
    set req.backend = polyfill_service;
    
    if (!req.http.Fastly-FF) {
      if (req.http.X-Forwarded-For) {
        set req.http.Fastly-Temp-XFF = req.http.X-Forwarded-For ", " client.ip;
      } else {
        set req.http.Fastly-Temp-XFF = client.ip;
      }
    } else {
      set req.http.Fastly-Temp-XFF = req.http.X-Forwarded-For;
    }

    set req.grace = 60s; 
    set req.http.host = "cdn.polyfill.io";

    # If this is an ESI request, unset Accept-Encoding to turn off zipping
    # We do NOT want any gzipping for ESI requests as they are not compatible
    # req.topurl: Exists in an ESI subrequest, returns the URL of the top-level request.
    # Polyfill service returns a Vary: Accept-Encoding, User-Agent
    if (req.topurl) {
      unset req.http.Accept-Encoding;
    }
  }
  
  return(lookup);
}