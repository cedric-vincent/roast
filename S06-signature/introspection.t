use v6;
use Test;
plan 48;

# L<S06/Signature Introspection>

sub j(*@i) {
    @i.map({ $_ ?? '1' !! '0' }).join(' ');
}

{
    sub a($x, Int $y?, :$z) { };   #OK not used
    ok &a.signature.params ~~ Positional, '.params does Positional';
    my @l = &a.signature.params;
    #?rakudo todo 'types or autothreading'
    ok ?(all(@l) ~~ Parameter), 'And all items are Parameters';
    is +@l, 3, 'we have three of them';
    is ~(@l>>.name), '$x $y $z', 'can get the names with sigils';
    ok @l[0].type === Any, 'Could get first type';
    ok @l[1].type === Int, 'Could get second type';

    is j(@l>>.readonly), '1 1 1', 'they are all read-only';
    is j(@l>>.rw),       '0 0 0', '... none rw';
    is j(@l>>.copy),     '0 0 0', '... none copy';
    is j(@l>>.ref),      '0 0 0', '... none ref';
    is j(@l>>.slurpy),   '0 0 0', '... none slurpy';
    is j(@l>>.optional), '0 1 1', '... some optional';
    is j(@l>>.invocant), '0 0 0', '... none invocant';
    is j(@l>>.named),    '0 0 1', '... one named';
}

#?rakudo skip 'is ref'
{
    sub b(:x($a)! is rw, :$y is ref, :$z is copy) { };   #OK not used
    my @l = &b.signature.params;
    #?rakudo todo 'is ref'
    is j(@l>>.readonly), '0 0 0', '(second sig) none are all read-only';
    is j(@l>>.rw),       '1 0 0', '... one rw';
    #?rakudo todo 'is ref'
    is j(@l>>.ref),      '0 1 0', '... one ref';
    is j(@l>>.copy),     '0 0 1', '... one copy';
    is j(@l>>.slurpy),   '0 0 0', '... none slurpy';
    is j(@l>>.optional), '0 1 1', '... some optional';
    is j(@l>>.invocant), '0 0 0', '... none invocant';
    is j(@l>>.named),    '1 1 1', '... one named';

    is ~@l[0].named_names, 'x',   'named_names work';
    is ~@l[0].name,      '$a',    '.name works for renamed params';
}

{
    sub d(*@pos, *%named) { };   #OK not used
    my @l = &d.signature.params;
    is j(@l>>.named),    '0 1', '.named for slurpies';
    is j(@l>>.slurpy),   '1 1', '.slurpy';
    is ~(@l>>.name),     '@pos %named', '.name for slurpies';
}


{
    sub d(:x(:y(:z($a)))) { };   #OK not used
    is ~&d.signature.params.[0].named_names.sort, 'x y z', 'multi named_names';
    is ~&d.signature.params.[0].name, '$a',    '... and .name still works';
}

{
    sub e($x = 3; $y = { 2 + $x }) { };   #OK not used
    my @l = &e.signature.params>>.default;
    #?rakudo todo 'types or autothreading'
    ok ?( all(@l) ~~ Code ), '.default returns closure';
    is @l[0].(),    3, 'first closure works';
    #?rakudo skip 'default closure when no call made fails lexical lookup with NPMCA'
    is @l[1].().(), 5, 'closure as default value captured outer default value';
}

{
    sub f(Int $x where { $_ % 2 == 0 }) { };   #OK not used
    my $p = &f.signature.params[0];
    #?rakudo todo 'constraints'
    ok 4  ~~ $p.constraints, '.constraints (+)';
    ok 5 !~~ $p.constraints, '.constraints (-)';
    ok 5 ~~ (-> $x { }).signature.params[0].constraints,
       '.constraints on unconstraint param should still smartmatch truely';
    sub g(Any $x where Int) { };   #OK not used
    #?rakudo todo 'constraints'
    ok 3 ~~ &g.signature.params[0].constraints,
       'smartmach against non-closure constraint (+)';
    ok !(3.5 ~~ &g.signature.params[0].constraints),
       'smartmach against non-closure constraint (-)';
}

# RT #70720
{
    is :(3).params[0].constraints, 3, ':(3) contains the 3';
    ok :(3).params[0].type === Int,   ':(3) has a parameter of type Int';
}

{
    sub h(::T $x, T $y) { };   #OK not used
    my @l = &h.signature.params;
    is @l[0].type_captures, 'T', '.type_captures';
    lives_ok { @l[1].type }, "can access a type_capture'd type";
}

{
    sub i(%h($a, $b)) { };   #OK not used
    my $s = &i.signature.perl;
    ok $s ~~ /'$a' >> /, '.perl on a nested signature contains variables of the subsignature (1)';
    ok $s ~~ /'$b' >> /, '.perl on a nested signature contains variables of the subsignature (2)';

}

{
    my $x;
    ok :(|$x).params[0].capture, 'prefix | makes .capture true';
    ok :(|$x).perl  ~~ / '|' /,  'prefix | appears in .perl output';

    #?rakudo 2 skip 'parcel binding'
    ok :(\|$x).params[0].parcel, 'prefix \| makes .parcel true';
    ok :(\|$x).perl ~~ / '\|' /, 'prefix \| appears in .perl output';
}

# RT #69492
{
    sub foo(:$) {};
    ok &foo.signature.perl ~~ / ':' /, '.perl of a signature with anonymous named parameter';
}

done;

# vim: ft=perl6
