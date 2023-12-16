use strict;
use warnings;

use Test::More;
use Time::HiRes qw<sleep>;
BEGIN { use_ok('Socket::More::Resolver') };

# This tests the polling of the resolver. 

use Socket::More::Resolver;

use Data::Dumper;
my $run=1;
getaddrinfo("www.google.com",0, {},
  sub { 
    print STDERR Dumper @_;
    $run=0;
  },
  sub {
    print STDERR Dumper @_;
    $run=0;
  }
);

sleep 0.1 and getaddrinfo while($run);

done_testing;
