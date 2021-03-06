use v6;

use Test;
# Test of PRE and POST traits
#
# L<S04/Phasers/"assert precondition at every block ">
# L<S06/Subroutine traits/PRE/POST>
#
# TODO: 
#  * Multiple inheritance + PRE/POST blocks

plan 25;

sub foo(Int $i) {
    PRE {
        $i < 5
    }
    return 1;
}

sub bar(Int $i) {
    return 1;
    POST {
        $i < 5;
    }
}

lives_ok { foo(2) }, 'sub with PRE  compiles and runs';
lives_ok { bar(3) }, 'sub with POST compiles and runs';

dies_ok { foo(10) }, 'Violated PRE  throws (catchable) exception';
dies_ok { bar(10) }, 'Violated POST throws (catchable) exception';

# multiple PREs und POSTs

sub baz (Int $i) {
	PRE {
		$i > 0
	}
	PRE {
		$i < 23
	}
	return 1;
}
lives_ok { baz(2) }, 'sub with two PREs compiles and runs';

dies_ok  { baz(-1)}, 'sub with two PREs fails when first is violated';
dies_ok  { baz(42)}, 'sub with two PREs fails when second is violated';


sub qox (Int $i) {
	return 1;
	POST {
		$i > 0
	}
	POST {
		$i < 42
	}
}

lives_ok({ qox(23) }, "sub with two POSTs compiles and runs");
dies_ok( { qox(-1) }, "sub with two POSTs fails if first POST is violated");
dies_ok( { qox(123)}, "sub with two POSTs fails if second POST is violated");

# inheritance

class PRE_Parent {
    method test(Int $i) {
        PRE {
            $i < 23
        }
        return 1;
    }
}

class PRE_Child is PRE_Parent {
    method test(Int $i){
        PRE {
            $i > 0;
        }
        return 1;
    }
}

my $foo = PRE_Child.new;

lives_ok { $foo.test(5)    }, 'PRE in methods compiles and runs';
dies_ok  { $foo.test(-42)  }, 'PRE in child throws';
#?niecza skip 'PRE inheritance'
dies_ok  { $foo.test(78)   }, 'PRE in parent throws';


class POST_Parent {
    method test(Int $i) {
        return 1;
        POST {
            $i > 23
        }
    }
}

class POST_Child is POST_Parent {
    method test(Int $i){
        return 1;
        POST {
            $i < -23
        }
    }
}
my $mp = POST_Child.new;

#?niecza 2 skip 'unspecced'
lives_ok  { $mp.test(-42) }, "It's enough if we satisfy one of the POST blocks (Child)";
lives_ok  { $mp.test(42)  }, "It's enough if we satisfy one of the POST blocks (Parent)";
dies_ok   { $mp.test(12) }, 'Violating poth POST blocks throws an error';

class Another {
    method test(Int $x) {
        return 3 * $x;
        POST {
            $_ > 4
        }
    }
}

my $pt = Another.new;
lives_ok { $pt.test(2) }, 'POST receives return value as $_ (succeess)';
dies_ok  { $pt.test(1) }, 'POST receives return value as $_ (failure)';

{
    my $str;
    {
        PRE  { $str ~= '('; 1 }
        POST { $str ~= ')'; 1 }
        $str ~= 'x';
    }
    is $str, '(x)', 'PRE and POST run on ordinary blocks';
}

{
    my $str;
    {
        POST  { $str ~= ')'; 1 }
        LEAVE { $str ~= ']' }
        ENTER { $str ~= '[' }
        PRE   { $str ~= '('; 1 }
        $str ~= 'x';
    }
    is $str, '([x])', 'PRE/POST run outside ENTER/LEAVE';
}

{
    my $str;
    try {
        {
            PRE     { $str ~= '('; 0 }
            PRE     { $str ~= '*'; 1 }
            ENTER   { $str ~= '[' }
            $str ~= 'x';
            LEAVE   { $str ~= ']' }
            POST    { $str ~= ')'; 1 }
        }
    }
    is $str, '(', 'failing PRE runs nothing else';
}

#?niecza skip 'I think POST runs LIFO by spec?'
{
    my $str;
    try {
        {
            POST  { $str ~= 'x'; 0 }
            LEAVE { $str ~= 'y' }
            POST  { $str ~= 'z'; 1 }
        }
    }
    is $str, 'yx', 'failing POST runs LEAVE but not more POSTs';
}

#?niecza skip 'unspecced'
{
    my $str;
    try {
        POST { $str ~= $! // '<undef>'; 1 }
        die 'foo';
    }
    ok $str ~~ /foo/, 'POST runs on exception, with correct $!';
}

#?niecza skip 'unspecced'
{
    my $str;
    try {
        POST { $str ~= (defined $! ?? 'yes' !! 'no'); 1 }
        try { die 'foo' }
        $str ~= (defined $! ?? 'aye' !! 'nay');
    }
    is $str, 'ayeno', 'POST has undefined $! on no exception';
}

#?niecza skip 'unspecced'
{
    try {
        POST { 0 }
        die 'foo';
    }
    ok $! ~~ /foo/, 'failing POST on exception doesn\'t replace $!';
    # XXX
    # is $!.pending.[-1], 'a POST exception', 'does push onto $!.pending';
}

# vim: ft=perl6
