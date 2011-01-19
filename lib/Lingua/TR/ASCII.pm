package Lingua::TR::ASCII;
use strict;
use warnings;
use utf8;
use base qw( Exporter );
use Lingua::TR::ASCII::Data;

our $VERSION = '0.10';
our @EXPORT  = qw( ascii_to_turkish turkish_to_ascii );

sub ascii_to_turkish {
    my($str) = @_;
    return __PACKAGE__->_new( $str )->_deasciify;
}

sub turkish_to_ascii {
    die "Unimplemented\n";
}

sub _new {
    my($class, $ascii_string) = @_;
    my $self = {
        ascii_string   => $ascii_string,
        turkish_string => $ascii_string,
    };
    bless $self, $class;
    return $self;
}

sub _deasciify {
    my($self) = @_;
    # Convert a string with ASCII-only letters into one with
    # Turkish letters.
    my @chars = split m{}xms, $self->{turkish_string};

    for my $i ( 0 .. $#chars ) {
        my $c = $chars[$i];
        if ( $self->_needs_correction( $c, $i ) ) {
            substr $self->{turkish_string}, $i, 1, $TOGGLE_ACCENT->{ $c } || $c;
        }
    }

    return $self->{turkish_string};
}

sub _needs_correction {
    my($self, $ch, $point) = @_;
    $point ||= 0;
    # Determine if char at cursor needs correction.
    my $tr = $ASCIIFY->{ $ch } || $ch;
    my $pl = $PATTERN->{ lc $tr };
    my $m  = $pl ? $self->_matches($pl, $point) : 0;

    return $tr eq 'I'
                ? ( $ch eq $tr ? ! $m :   $m )
                : ( $ch eq $tr ?   $m : ! $m )
                ;
}

sub _matches {
    my($self, $dlist, $point) = @_;
    $point ||= 0;
    # Check if the pattern is in the pattern table.
    my $rank  = 2 * keys %{ $dlist };
    my $str   = $self->_get_context( $point );
    my $start = 0;
    my $end   = 0;

    my $_len = length $str;

    while ( $start <= CONTEXT_SIZE ) {
        $end = 1 + CONTEXT_SIZE;
        while ( $end <= $_len ) {
            my $s = substr $str, $start, $end - $start;
            my $r = $dlist->{ $s };
            $rank = $r if $r && abs $r < abs $rank;
            $end++;
        }
        $start++;
    }

    return $rank > 0;
}

sub _get_context {
    my($self, $point, $size) = @_;
    $size ||= CONTEXT_SIZE;
    my $s = q{ } x ( 1 + ( 2 * $size ) );
    substr $s, $size, 1, 'X';

    my $i       = 1 + $size;
    my $index   = $point;
    my $space;

    my $current_char = substr $self->{turkish_string}, $index, 1;

    $index++;

    while ( $i < length($s) && ! $space && $index < length($self->{ascii_string}) ) {
        $current_char = substr $self->{turkish_string}, $index, 1;
        my $x = $DOWNCASE_ASCIIFY->{ $current_char };
        if ( ! $x ) {
            if ( ! $space ) {
                $i++;
                $space = 1;
            }
        }
        else {
            substr $s, $i, 1, $x;
            $i++;
            $space = 0;
        }
        $index++;
    }

    $s     = substr $s, 0, $i;
    $index = $point;
    $i     = $size - 1;
    $space = 0;
    $index--;

    while ( $i >= 0 && $index >= 0 ) {
        $current_char = substr $self->{turkish_string}, $index, 1;
        my $x = $UPCASE_ACCENTS->{ $current_char };

        if ( ! $x ) {
            if ( ! $space ) {
                $i--;
                $space = 1;
            }
        }
        else {
            substr $s, $i, 1, $x;
            $i--;
            $space = 0;
        }
        $index--;
    }

    return $s;
}

1;

__END__

=pod

=head1 NAME

Lingua::TR::ASCII - (De)asciify Turkish texts.

=head1 SYNOPSIS

    use Lingua::TR::ASCII;
    print ascii_to_turkish(
        'Acimasizca acelya gorunen bir sacmaliktansa acilip sacilmak...'
    );

=head1 DESCRIPTION

If you try to write Turkish with a non-Turkish keyboard (assuming you
can't change the layout or can't touch-type) this'll result with the
ascii-fication of the Turkish characters and this actually results
with bogus text since the text you wrote is not literally Turkish
(although the Turkish speaking people and search engines will most
likely understand it). And in some cases, ascii-fication of some sentences
might result with funny words. This module tries to mitigate this problem
with a wrapper around a pre-compiled decison list.

The original creator of the decision list states that it was "created based
on 1 million words of Turkish news text using the GPA algorithm". See
the links below for more information.

This module is based on the previous Python and Ruby implementations.

=head1 FUNCTIONS

=head2 ascii_to_turkish

Converts (corrects) the supplied string into Turkish.

=head2 turkish_to_ascii

Not yet implemented.

=head1 SEE ALSO

L<Lingua::DE::ASCII>,
L<http://ileriseviye.org/blog/?tag=turkish-deasciifier>,
L<http://www.denizyuret.com/2006/11/emacs-turkish-mode.html>.

=head2 OTHER IMPLEMENTATIONS

=head3 Languages

=over 4

=item JavaScript

L<http://turkce-karakter.appspot.com>

=item Python

L<https://github.com/emres/turkish-deasciifier>

=item Ruby

L<https://github.com/berkerpeksag/ruby-turkish-deasciifier>.

=item Java

L<http://code.google.com/p/turkish-deasciifier>

=back

=head3 Tools

=over 4

=item Firefox Add-on

L<https://addons.mozilla.org/en-US/firefox/addon/turkish-deasciifier>.

=back

=cut
