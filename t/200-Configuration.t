##############################################################################
# This test file tests the functions found in the Configuration section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  createConfiguration => {
    description => "Adds configuration value",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => { description => "the description of the configuration", value => "the value of the configuration", },
      required => {
        category  => "component's category",
        component => "the component of the configuration",
        instance  => "the instance of the configuration",
        name      => "the name of the configuration",
      },
    },
    response => {
      category    => "the category of the configuration",
      description => "the description of the configuration",
      name        => "the name of the configuration",
      value       => "the value of the configuration",
    },
    section => "Configuration",
  },
  listCapabilities => {
    description => "Lists capabilities",
    isAsync     => "false",
    level       => 15,
    request     => undef,
    response    => {
      cloudstackversion         => "version of the cloud stack",
      firewallRuleUiEnabled     => "true if the firewall rule UI is enabled",
      securitygroupsenabled     => "true if security groups support is enabled, false otherwise",
      supportELB                => "true if region supports elastic load balancer on basic zones",
      userpublictemplateenabled => "true if user and domain admins can set templates to be shared, false otherwise",
    },
    section => "Configuration",
  },
  listConfigurations => {
    description => "Lists all configurations.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => {
        category => "lists configurations by category",
        keyword  => "List by keyword",
        name     => "lists configuration by name",
        page     => "no description",
        pagesize => "no description",
      },
    },
    response => {
      category    => "the category of the configuration",
      description => "the description of the configuration",
      name        => "the name of the configuration",
      value       => "the value of the configuration",
    },
    section => "Configuration",
  },
  updateConfiguration => {
    description => "Updates a configuration.",
    isAsync     => "false",
    level       => 1,
    request     => {
      optional => { value => "the value of the configuration" },
      required => { name  => "the name of the configuration" },
    },
    response => {
      category    => "the category of the configuration",
      description => "the description of the configuration",
      name        => "the name of the configuration",
      value       => "the value of the configuration",
    },
    section => "Configuration",
  },
};

sub random_text {

  my @c = ( 'a' .. 'z', 'A' .. 'Z' );
  return join '', map { $c[ rand @c ] } 0 .. int( rand 16 ) + 8;

}

my $base_url   = 'http://somecloud.com';
my $api_path   = 'client/api?';
my $api_key    = random_text();
my $secret_key = random_text();

my $tests = 1;  # Start at 1 for Test::NoWarnings
$tests++;       # Test loading of Configuration group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Configuration'; 1", 'use statement' ) } 'use took';
explain $@ if $@;

my $obj = Net::CloudStack::API->new;
isa_ok( $obj, 'Net::CloudStack::API' );

my $oo_api = $obj->api( {

    base_url   => $base_url,
    api_path   => $api_path,
    api_key    => $api_key,
    secret_key => $secret_key,

} );

isa_ok( $oo_api, 'Net::CloudStack' );

# MatchURL::match expects
# $check_url, $base_url, $api_path, $api_key, $secret_key, $cmd, $pairs (optional)
my @data = ( $base_url, $api_path, $api_key, $secret_key );

for my $m ( keys %$method ) {

  explain( "Working on $m method" );

  my $work = $method->{ $m };

  SKIP: {

    skip 'no required parameters', 2
        if ! exists $work->{ request }{ required };

    # Test call with no arguments
    my $check_regex = qr/Mandatory parameters? .*? missing in call/i;
    throws_ok { $obj->$m } $check_regex, 'caught missing required params (oo)';

    no strict 'refs';
    throws_ok { $m->() } $check_regex, 'caught missing required params (functional)';

  }

  my ( %args, @args );

  if ( exists $work->{ request }{ required } ) {
    for my $parm ( keys %{ $work->{ request }{ required } } ) {

      $args{ $parm } = random_text();
      push @args, [ $parm, $args{ $parm } ];

    }
  }

  my $check_url;
  ok( $check_url = $obj->$m( \%args ), 'check_url created (oo)' );
  ok( MatchURL::match( $check_url, @data, $m, \@args ), 'urls matched (oo)' );

  { no strict 'refs'; ok( $check_url = $m->( \%args ), 'check_url created (functional)' ) }
  ok( MatchURL::match( $check_url, @data, $m, \@args ), 'urls matched (functional)' );

} ## end for my $m ( keys %$method)
