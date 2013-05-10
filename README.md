# Frenetic  [![Gem Version][version_badge]][version] [![Build Status][travis_status]][travis]

[version_badge]: https://badge.fury.io/rb/frenetic.png
[version]: http://badge.fury.io/rb/frenetic
[travis_status]: https://secure.travis-ci.org/dlindahl/frenetic.png
[travis]: http://travis-ci.org/dlindahl/frenetic

An opinionated Ruby-based Hypermedia API (HAL+JSON) client.



## About

fre&bull;net&bull;ic |frəˈnetik|<br/>
adjective<br/>
fast and energetic in a rather wild and uncontrolled way : *a frenetic pace of activity.*

So basically, this is a crazy way to interact with your Hypermedia HAL+JSON API.

Get it? *Hypermedia*?

*Hyper*?

...

If you have not implemented a HAL+JSON API, then this will not work very well for you.





## Opinions

Like I said, it is opinionated. It is so opinionated, it is probably the biggest
a-hole you've ever met.

Maybe in time, if you teach it, it will become more open-minded.


### HAL+JSON Content Type

Frenetic expects all responses to be in [HAL+JSON][hal_json]. It chose that
standard because it is trying to make JSON API's respond in a predictable
manner, which it thinks is an awesome idea.


### API Description

The API's root URL must respond with a description, much like the
[Spire.io][spire.io] API.

This is crucial in order for Frenetic to work. If Frenetic doesn't know what
the API contains, it can't navigate around it or parse any of it's responses.

**Example:**

```js
// GET http://example.com/api
{
  "_links": {
    "self": {
      "href": "/api/"
    },
    "orders": {
      "href":"/api/orders"
    },
    "order": {
      "href": "/api/orders/{id}",
      "templated": true
    }
  },
  "_embedded": {
    "schema": {
      "_links": {
        "self": { "href":"/api/schema" }
      },
      "order": {
        "description": "A widget order",
        "type": "object",
        "properties": {
          "id": { "type":"integer" },
          "first_name": { "type":"string" },
          "last_name": { "type":"string" },
        }
      }
    }
  }
}
```

This response will be requested by Frenetic whenever a call to
`YourAPI.description` is made.

**Note:** It is highly advised that you implement some sort of caching in both
your API server as well as your API client. Refer to the [Caching][caching] section for
more information.





## Configuring

### Client Initialization

Initializing an API client is really easy:

```ruby
class MyApiClient
  # Arbitrary example
  def self.api
    @api ||= Frenetic.new( url:'http://example.com/api' )
  end
end
```

At the bare minimum, Frenetic only needs to know what the URL of your API is.


### Configuring

Configuring Frenetic can be done during instantiation:

```ruby
Frenetic.new( url:'http://example.com', api_token:'123bada55k3y' )
```

Or with a block:

```ruby
f = Frenetic.new
f.configure do |cfg|
  cfg.url = 'http://example.com'
  cfg.api_token = '123bada55key'
end
```

Or both...

```ruby
f = Frenetic.new( url:'http://example.com' )
f.configure do |cfg|
  cfg.api_token = '123bada55key'
end
```

#### Authentication

Frenetic supports both Basic Auth and Tokens Auth via the appropriate Faraday
middleware.

##### Basic Auth

To use Basic Auth, simply configure Frenetic with a `username` and `password`:

```ruby
Frenetic.new( url:url, username:'user', password:'password' )
```

If your API uses an App ID and API Key pair, you can pass those as well:

```ruby
Frenetic.new( url:url, app_id:'123abcSHA1', api_key:'bada55SHA1k3y' )
```

The `app_id` and `api_key` values are simply aliases to `username` and
`password`

##### Token Auth

To use Token Auth, simply configure Frenetic with your token:

```ruby
Frenetic.new( url:url, api_token:'bada55SHA1t0k3n' )
```


#### Response Caching

If configured to do so, Frenetic will autotmatically cache API responses.

*It is highly recommended that you turn this feature on!*

##### Rack::Cache

```ruby
Frenetic.new( url:url, cache: :rack )
```

Passing in a cache option of `:rack` will cause Frenetic to use Faraday's
`Rack::Cache` middleware with a set of sane default configuration options.

If you wish to provide your own configuration options:

```ruby
Frenetic.new({
  url: url,
  cache: {
    metastore:     'file:tmp/rack/meta',
    entitystore:   'file:tmp/rack/body',
    ignore_headers: %w{Authorization Set-Cookie X-Content-Digest}
  }})
```

Any key/value pair contained in the `cache` hash will be passed directly onto
the Rack::Cache middleware.

##### Memcached

**TODO**


#### Faraday Middleware

Frenetic will yield its internal Faraday connection during initialization:

```ruby
Frenetic.new( url:url ) do |builder|
  # `builder` is the Faraday Connection instance with which you can
  # add additional Faraday Middlewares or tweak the configuration.
end
```

You can then use the `builder` object as you see fit.




## Usage

Once you have created a client instance, you are free to use it however you'd
like.

A Frenetic instance supports any HTTP verb that [Faraday][faraday] has
impletented. This includes GET, POST, PUT, PATCH, and DELETE.

```ruby
api = Frenetic.new( url:url )

api.get '/my_things/1'
# { 'id' => 1, 'name' => 'My Thing', '_links' => { 'self' { 'href' => '/api/my_things/1' } } }
```

### Frenetic::Resource

An easier way to make requests for a resource is to create an object that
inherits from `Frenetic::Resource`.

Not only does `Frenetic::Resource` handle the parsing of the raw API response
into a Ruby object, but it also makes it a bit easier to encapsulate all of your
resource's API requests into one place.

```ruby
class Order < Frenetic::Resource

  api_client { MyAPI }

  # TODO: Write a better example for this.
  def self.find_all_by_name( name )
    api.get( search_url(name) ) and response.success?
  end
end
```

The `api_client` class method merely tells `Frenetic::Resource` which API Client
instance to use. If you lazily instantiate your client, then you should pass a
block as demonstrated above.

Otherwise, you may pass by reference:

```ruby
class Order < Frenetic::Resource
  api_client MyAPI
end
```

When your model is initialized, it will contain getter methods for every
property defined in your API's schema/description.

Each time a request is made for a resource, Frenetic checks the API to see if
the schema has changed. If so, it will redefine the the getter methods available
on your Class. This is what Hypermedia APIs are all about, a loose coupling
between client and server.





## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

I would love to hear how other people are using this (if at all) and am open to
ideas on how to support other Hypermedia formats like [Collection+JSON][coll_json].

[hal_json]: http://stateless.co/hal_specification.html
[spire.io]: http://api.spire.io/
[caching]: #response-caching
[faraday]: https://github.com/technoweenie/faraday
[rack_cache]: https://github.com/rtomayko/rack-cache
[coll_json]: http://amundsen.com/media-types/collection/