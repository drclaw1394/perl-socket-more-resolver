use strict;
use warnings;

use Test::More;
use Time::HiRes qw<sleep>;
#BEGIN { use_ok('Socket::More::Resolver') };

# This tests the polling of the resolver. 

use Socket::More::Resolver {max_workers=>5};

use Data::Dumper;
my $run=1;
getaddrinfo("www.google.com",0, {},
  sub { 
    print STDERR Dumper @_;
    ok 1, "Resolved google";
    $run=0;
  },
  sub {
    print STDERR Dumper @_;
    $run=0;
  }
);

say STDERR "MORE";
sleep 0.1 and getaddrinfo while($run);
say STDERR "AFTER";
#sleep 20;
#say STDERR "after cleanup";
#Socket::More::Resolver::cleanup();
done_testing;
