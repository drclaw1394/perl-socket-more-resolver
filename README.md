# NAME

Socket::More::Resolver - Loop Agnostic Asynchronous DNS Resolving

# SYNOPSIS

Automatic Event Loop Integration and support

```perl
use v5.36;

use AnyEvent; # or IO::Async, Mojo::IOLoop

use Socket::More::Resolver; 

getaddrinfo("www.google.com", 0, {},
  sub {
    # got results
  },
  sub {
    # got an error
    say gai_strerror $_[0];
  }


# Normal Event loop setup
my $cv=AE::cv;
$cv->recv;
```

# DESCRIPTION

Easy to use asynchronous DNS resolution with automatic integration into
supported event loops or polled manually.

It is stand alone module for small footprint, and is a part of the super
package [Socket::More](https://metacpan.org/pod/Socket%3A%3AMore).

Key features:

- Automatically integrates into supported event loops 

    [AnyEvent](https://metacpan.org/pod/AnyEvent), [IO::Async](https://metacpan.org/pod/IO%3A%3AAsync), [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop) are currently supported where
    detected. Driver for other loops can be easily added. Non blocking polling is
    also supported.

- Extendable Event Loop Support

    The user can write a 'driver' for other event loops (and put them on CPAN!)

- Utilises your systems `getaddrinfo` and `getnameinfo`

    Gives the results you would expect from your system configuration

- Pure Perl

    Uses core Perl [Socket](https://metacpan.org/pod/Socket). If [Socket::More::Lookup](https://metacpan.org/pod/Socket%3A%3AMore%3A%3ALookup) is available it will be
    used instead.

- Threadless Self Managed Worker Pool

    The non blocking and asynchronous behaviour is achieved with a fully contained
    and self managing worker pool, no threaded Perl required) and optimised for low
    memory usage and DNS queries.

# Limitations and Features to be explored

- Future/Promise API

    Make a version of getaddrinfo to return Futures/Promises instead of using
    callbacks, because people like those.

- Internal mDNS Resolver

    The worker pool works very well for fast DNS lookups, however mDNS lookups take
    up to 5 seconds (by design), when a name is unkown. This can easily saturate
    the worker pool if you ask multiple 'wrong names' quickly

# USAGE 

The resolver is designed to work with or without an event loop with as little
fuss as possible. Import your event loop first, if using one, then this module:

```perl
#use AnyEvnet; #use IO::Async; #use Mojo::IOLoop
use Socket::More::Resolver; 

```

This will perform automatic loop integration, pool management with default
options and export all symbols and automatically start the worker pool, if it
hasn't already been started. 

## Import Options

Thanks to [Export::These](https://metacpan.org/pod/Export%3A%3AThese) managing this modules exports, module options and
symbols can be specified at import time with a hash ref in the import list:

```perl
use Socket::More::Resolver {options}, symbols ...;

eg
use Socket::More::Resolver {max_workers=>10, prefork=>1}, qw<getaddrinfo>;
```

There a handful of options which influence the resolver operation. These are
specified as hash ref at import:

- max\_workers

    ```perl
    max_worker=>number
    ```

    Sets the maximum number of workers to spawn. The default is 4.

- prefork

    ```perl
    prefork=>bool
    ```

    Start all workers at launch instead of as needed.

- no\_export

    ```perl
    no_export=>1
    ```

    When set to a true value, prevents the exporting of symbols into the target
    namespace.

- no\_loop

    ```perl
    no_loop=>bool
    ```

    When set prevents the integration into event loop. Testing use mainly.

- loop\_driver

    ```perl
    loop_driver=>string
    loop_driver=>ARRAY
    loop_driver=>CODE
    ```

    Provides a hook mechanism to add support for other event loops. If a string or
    array ref are provided, the contents are unshifted to the internal 'search
    list' of event loop package names.  

    If these packages are loaded, then the first one detected will be considered
    the event loop to use. 

    If a code ref is provided, package name search is bypassed and  the code ref is
    used as a callback.

    See the below on writing a driver.

## API

The API is focused on asyncrhonous usage. That means callbacks are used for
reporting results and errors.

### getaddrinfo

```perl
getaddrinfo(host, port, hints, on_results, on_error);

eg

  getaddrinfo 
    "www.google.com",
    80,
    {family=>AF_INET}, 
    sub {
      for(@_){
        # Process results
      }
    },
    sub {
      # Handle error
    }
```

`host` is the hostname or numerical address of the host to resolve
`port` is the port of the host to use
`hints` is hash of hints to adjust processing and restrict results
Please refer to [Socket](https://metacpan.org/pod/Socket) or [Socke::More::Lookup](https://metacpan.org/pod/Socke%3A%3AMore%3A%3ALookup) for details on how these
values are used.

`on_results` is callback which is called with the results from the query if no error occured.
`on_error` is callback which is called with an error code.

The return value represents the number of oustanding  requests/messages to be
preocessed. This will always be a > 0 when resolving a host.

However, if called with no arguments, services the request queue and checks for
availability of results.  When not using an event loop this acts as the polling
mechanism:

```
eq
 getaddrinfo(...);

 while(getaddrinfo){
  # poll here until all requests are processed
 }
```

### getnameinfo 

# Supporting other event loops

If you need to add an event loop which isn't directly supported, the easiest
way is to look at the code for one of the existing drivers.

TODO: document this more

# How it works (High Level)

When the [Socket::More::Resolver](https://metacpan.org/pod/Socket%3A%3AMore%3A%3AResolver) package is loaded for the first time, it
initialises a pool of pipes to be used by workers.  The first 'worker', is used
as a templates process and is spawned (forked and exec) into the
[Socket::More::Resolver::Worker](https://metacpan.org/pod/Socket%3A%3AMore%3A%3AResolver%3A%3AWorker).

Lookup requests are sent to remaining workers which are active to process the
blocking request to `getaddrinfo` or `getnameinfo`.

Process reaping and respawning etc is automatic,

TODO: Document more

# COMPARISION TO OTHER MODULES

[Net::DNS::Native](https://metacpan.org/pod/Net%3A%3ADNS%3A%3ANative)

```
Uses Internal C level threads
Returns file handles for each resolution request
Awkward interface for integration into event loop
```

[IO::Async](https://metacpan.org/pod/IO%3A%3AAsync)

```perl
Uses Socket module
Purportedly asynchronouse getaddrinfo, but can block on a single slow request
```

[Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop)

```
Uses Net::DNS::Native
```

[AnyEvent](https://metacpan.org/pod/AnyEvent)

```perl
Implements it's own resolver
Doesn't use system confuration
Doesn't work with .local multicast DNS
```
