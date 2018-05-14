package Class::Method::Cache::FastMmap;

# ABSTRACT: Cache method results using Cache::FastMmap

use v5.10.1;

use strict;
use warnings;

use base 'Exporter::Tiny';

use Cache::FastMmap;
use Class::Method::Modifiers qw/ install_modifier /;
use Object::Signature ();

our $VERSION = 'v0.3.1';

our @EXPORT    = qw/ cache /;
our @EXPORT_OK = @EXPORT;

=head1 SYNOPSIS

  package MyClass;

  use Class::Method::Cache::FastMmap;

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

=export C<cache>

  cache $method => %options;

This wraps the C<$method> with a function that caches the return value.

It assumes that the method returns a defined scalar value and that the
method arguments are serialisable.

The C<%options> are as follows:

=over 4

=item C<cache>

is used to specify a different (shared) cache. You may use another
caching class, so long as it provides C<get> and C<set> methods.

Added v0.2.0.

=item C<key_cb>

is used to provide a custom key-generation function.  If
none is specified, then L<Object::Signature> is used.

The function should expect a single argument with an array reference
corresponding to the original method call parameters:

  $key_cb->( [ $self, @_ ] );

=item C<prefix>

This is the prefix too prepend to the key. It defaults to the class
and method name when the L</cache> is specified, or an empty string
otherwise.

Added v0.2.0.

=back

Remaining C<%options> are passed to the constructor for
L<Cache::FastMmap>.

As of v0.3.0, you can import the C<cache> method with a different
namme:

  use Class::Method::Cache::FastMmap
     "cache" => { -as => "memoize" };

  sub my_method {
    ...
  }

  memoize 'my_method' => (
     serializer  => 'storable',
     expire_time => '1h',
  );

Undefined results are not cached. So if your method returns C<undef>
on failure, then it never cache that result.

=cut

sub cache {
    my ( $method, %options ) = @_;

    my $target = caller;

    my $global = delete $options{cache};
    my $prefix = delete $options{prefix}
      // ( $global ? "${target}::${method}::" : '' );
    my $key_cb = delete $options{key_cb} // \&Object::Signature::signature;

    install_modifier $target, 'around', $method, sub {
        my $next = shift;
        my $self = shift;

        state $cache = $global // Cache::FastMmap->new(%options);

        my $key = $prefix . $key_cb->( [ $self, @_ ] );
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

=head1 append:AUTHOR

Some development of this module was sponsored by Science Photo Library
L<https://www.sciencephoto.com>.

=cut

1;
