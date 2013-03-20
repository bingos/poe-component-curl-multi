package POE::Component::Curl::Multi;

#ABSTRACT: a fast HTTP POE component

use strict;
use warnings;
use HTTP::Response;
use WWW::Curl;
use WWW::Curl::Easy;
use WWW::Curl::Multi;
use Scalar::Util qw[refaddr];
use POE;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{timeout} = 180 unless $self->{timeout} && $self->{timeout} =~ m!^\d+$!;
  $self->{followredirects} = 0 unless
    $self->{followredirects} && $self->{followredirects} =~ m!^(-1|[0-9]+)$!;
  # dela with noproxy
  $self->{multi_h} = WWW::Curl::Multi->new();
  $self->{session_id} = POE::Session->create(
        object_states => [
           $self => { shutdown => '_shutdown', request => '_request' },
           $self => [qw(_start _resolve _lookup _reason)],
        ],
        heap => $self,
        ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
     $kernel->alias_set( $self->{alias} );
  }
  else {
     $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  return;
}

sub _request {
}
