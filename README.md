# Guardian Polyfill Service

This project includes VCL for https://polyfill.guim.co.uk/ which runs on Fastly.
It is intended to be called from ESIs (Edge Side Includes) or client-side code.

It it a proxy to the https://polyfill.io/ service run by Fastly and FT.


## Calls from client-side code

To call from the client-side, make your call as you would with `polyfill.io`:

##### Example: Polyfill fetch only

```
https://polyfill.guim.co.uk/v2/polyfill.min.js?features=fetch
```

#### Example: Polyfill Array.prototype.contains and Element.classList

```
https://polyfill.guim.co.uk/v2/polyfill.min.js?features=Array.prototype.contains,Element.classList
```

To see a full list of features that can be polyfilled, (look here)[https://polyfill.io/v2/docs/features/].



## Calls from ESI

Currently a static site on S3 is serving files with ESI tags in it.


#### Example

For example, the file at 

```
https://polyfill.guim.co.uk/promise-find-from-includes-intersection.js
```

includes the following ESI:

```
<esi:include src="/v2/polyfill.min.js?features=Promise,Array.prototype.find,Array.from,Array.prototype.includes,IntersectionObserver" />
```

### ESI Notes

ESIs and gzipping are incompatible; we strip out the `Accept-Encoding` header sent along when an ESI is used.

Currently, the request for the JS file in the example is stripping out the header for both the original request AND the ESI request meaning none of it ever gets compressed.