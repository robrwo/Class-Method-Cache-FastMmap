package Class::Method::Cache;

use v5.10.1;

use strict;
use warnings;

use Cache::FastMmap;
use Class::Method::Modifiers qw/ install_modifier /;
use Exporter qw/ import /;
use Object::Signature ();

our $VERSION = 'v0.1.0';

our @EXPORT    = qw/ cache /;
our @EXPORT_OK = @EXPORT;

sub cache {
    my ( $method, %options ) = @_;

    my $target = caller;

    my $key_cb = delete $options{key_cb} // \&Object::Signature::signature;

    install_modifier $target, 'around', $method, sub {
        my $next = shift;
        my $self = shift;

        state $cache = Cache::FastMmap->new(%options);

        my $key = $key_cb->( [ $self, @_ ] );
        my $value = $cache->get($key);
        unless ( defined $value ) {
            $cache->set( $key, $value = $self->$next(@_) );
        }
        return $value;
    };

}

1;
