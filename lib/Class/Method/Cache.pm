package Class::Method::Cache;

# ABSTRACT: Cache method results using Cache::FastMmap

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

=head1 SYNOPSIS

  package MyClass;

  use Class::Method::Cache;

  sub my_method {
    ...
  }

  cache 'my_method' => (
     serializer  => 'storable',
     expire_time => '1h',
  );

=head1 DESCRIPTION

This package allows you to easily cache the results of a method call
using L<Cache::FastMmap>.

=head1 EXPORTS

=head2 C<cache>

  cache $method => %options;

This wraps the C<$method> with a function that caches the return value.

It assumes that the method returns a defined scalar value and that the
method arguments are serialisable.

The C<%options> are used to configure L<Cache::FastMmap>.

A special option called C<key_cb> is used to provide a custom
key-generation function.  If none is specified, then
L<Object::Signature> is used.

The function should expect a single argument with an array reference
corresponding to the original method call parameters:

  $key_cb->( [ $self, @_ ] );

=cut

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

=head1 SEE ALSO

L<Cache::FastMmap>

L<Object::Signature>

=cut

1;
