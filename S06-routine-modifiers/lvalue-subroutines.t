use v6;

use Test;

plan 14;

=begin description

Testing lvalue-returning subroutines

=end description

# L<S06/"Lvalue subroutines">

# Lvalue subrefs
{
  my $var1 = 1;
  my $var2 = 2;

  my $lastvar = sub () is rw { return $var2      };
  my $prevvar = sub () is rw { return $lastvar() };

  $lastvar() = 3;
  is $var2, 3, "lvalue subroutine references work (simple)";

  $prevvar() = 4;
  is $var2, 4, "lvalue subroutine references work (nested)";
}

{
  my $var = 42;
  my $notlvalue = sub () { return $var };

  #?pugs 2 todo 'bug'
  dies_ok { $notlvalue() = 23 },
    "assigning to non-rw subrefs should die";
  is $var, 42,
    "assigning to non-rw subrefs shouldn't modify the original variable";
}

{
  my $var1 = 1;
  my $var2 = 2;

  sub lastvar is rw { return $var2; }
  sub prevvar is rw { return lastvar(); }

  lastvar() = 3;
  is($var2, 3, "lvalue subroutines work (simple)");

  prevvar() = 4;
  is($var2, 4, "lvalue subroutines work (nested)");
}

{
  my $var = 42;

  # S6 says that lvalue subroutines are marked out by 'is rw'
  sub notlvalue { return $var; } # without rw

  dies_ok { notlvalue() = 5 },
    "assigning to non-rw subs should die";
  is $var, 42,
    "assigning to non-rw subs shouldn't modify the original variable";
}

my $val2; # XXX prevent parsefail below, not sure what test wants

sub check ($passwd) { return $passwd eq "fish"; };

sub checklastval ($passwd) is rw {
    my $proxy is Proxy(
    FETCH => sub ($self) {   #OK not used
            return lastval();
         },
    STORE => sub ($self, $val) {   #OK not used
            die "wrong password" unless check($passwd);
            lastval() = $val;
         }
    );
    return $proxy;
};

my $errors;
dies_ok {checklastval("octopus") = 10 }, 'checklastval STORE can die';

# Above test may well die for the wrong reason, if the Proxy stuff didn't
# parse OK, it will complain that it couldn't find the desired subroutine
is((try { checklastval("fish") = 12; $val2 }), 12, 'proxy lvalue subroutine STORE works');
my $resultval = checklastval("fish");
is($resultval, 12, 'proxy lvalue subroutine FETCH works');

my $realvar = "foo";
sub proxyvar ($prefix) is rw {
    return Proxy.new(
        FETCH => { $prefix ~ lc($realvar) },
        STORE => { lc($realvar = $^val) },
    );
}
is proxyvar("PRE"), 'PREfoo', 'proxy lvalue subroutine FETCH works';
# Return value of assignments of Proxy objects is decided now.
# See thread "Assigning Proxy objects" on p6l,
# L<"http://www.nntp.perl.org/group/perl.perl6.language/21838">.
# Quoting Larry:
#   The intention is that lvalue subs behave in all respects as if they
#   were variables.  So consider what
#   
#       say $nonproxy = 40;
#   
#   should do.
is (proxyvar("PRE") = "BAR"), 'BAR',
    'proxy lvalue subroutine STORE works and returns the correct value';
#?pugs todo 'feature'
is $realvar, 'BAR', 'variable was modified';

# vim: ft=perl6
