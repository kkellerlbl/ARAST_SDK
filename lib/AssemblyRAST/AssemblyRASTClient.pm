package AssemblyRAST::AssemblyRASTClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

AssemblyRAST::AssemblyRASTClient

=head1 DESCRIPTION


A KBase module: AssemblyRAST
This modules run assemblers supported in the AssemblyRAST service.


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => AssemblyRAST::AssemblyRASTClient::RpcClient->new,
	url => $url,
	headers => [],
    };

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my %arg_hash2 = @args;
	if (exists $arg_hash2{"token"}) {
	    $self->{token} = $arg_hash2{"token"};
	} elsif (exists $arg_hash2{"user_id"}) {
	    my $token = Bio::KBase::AuthToken->new(@args);
	    if (!$token->error_message) {
	        $self->{token} = $token->token;
	    }
	}
	
	if (exists $self->{token})
	{
	    $self->{client}->{token} = $self->{token};
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 run_kiki

  $output = $obj->run_kiki($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_kiki
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_kiki (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_kiki:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_kiki');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_kiki",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_kiki',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_kiki",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_kiki',
				       );
    }
}
 


=head2 run_velvet

  $output = $obj->run_velvet($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_velvet
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_velvet (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_velvet:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_velvet');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_velvet",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_velvet',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_velvet",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_velvet',
				       );
    }
}
 


=head2 run_miniasm

  $output = $obj->run_miniasm($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_miniasm
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_miniasm (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_miniasm:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_miniasm');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_miniasm",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_miniasm',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_miniasm",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_miniasm',
				       );
    }
}
 


=head2 run_spades

  $output = $obj->run_spades($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_spades
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_spades (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_spades:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_spades');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_spades",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_spades',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_spades",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_spades',
				       );
    }
}
 


=head2 run_idba

  $output = $obj->run_idba($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_idba
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_idba (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_idba:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_idba');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_idba",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_idba',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_idba",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_idba',
				       );
    }
}
 


=head2 run_megahit

  $output = $obj->run_megahit($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_megahit
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_megahit (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_megahit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_megahit');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_megahit",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_megahit',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_megahit",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_megahit',
				       );
    }
}
 


=head2 run_ray

  $output = $obj->run_ray($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_ray
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_ray (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_ray:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_ray');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_ray",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_ray',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_ray",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_ray',
				       );
    }
}
 


=head2 run_masurca

  $output = $obj->run_masurca($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_masurca
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_masurca (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_masurca:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_masurca');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_masurca",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_masurca',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_masurca",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_masurca',
				       );
    }
}
 


=head2 run_a5

  $output = $obj->run_a5($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_a5
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_a5 (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_a5:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_a5');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_a5",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_a5',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_a5",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_a5',
				       );
    }
}
 


=head2 run_a6

  $output = $obj->run_a6($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.AssemblyParams
$output is an AssemblyRAST.AssemblyOutput
AssemblyParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	min_contig_len has a value which is an int
	extra_params has a value which is a reference to a list where each element is a string
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_a6
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_a6 (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_a6:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_a6');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_a6",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_a6',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_a6",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_a6',
				       );
    }
}
 


=head2 run_arast

  $output = $obj->run_arast($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyRAST.ArastParams
$output is an AssemblyRAST.AssemblyOutput
ArastParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	recipe has a value which is a string
	assembler has a value which is a string
	pipeline has a value which is a string
	min_contig_len has a value which is an int
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyRAST.ArastParams
$output is an AssemblyRAST.AssemblyOutput
ArastParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	read_library_names has a value which is a reference to a list where each element is a string
	read_library_refs has a value which is a reference to a list where each element is a string
	output_contigset_name has a value which is a string
	recipe has a value which is a string
	assembler has a value which is a string
	pipeline has a value which is a string
	min_contig_len has a value which is an int
AssemblyOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text

=item Description



=back

=cut

 sub run_arast
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_arast (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_arast:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_arast');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyRAST.run_arast",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_arast',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_arast",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_arast',
				       );
    }
}
 
  
sub status
{
    my($self, @args) = @_;
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function status (received $n, expecting 0)");
    }
    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
        method => "AssemblyRAST.status",
        params => \@args,
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => 'status',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method status",
                        status_line => $self->{client}->status_line,
                        method_name => 'status',
                       );
    }
}
   

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "AssemblyRAST.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'run_arast',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method run_arast",
            status_line => $self->{client}->status_line,
            method_name => 'run_arast',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for AssemblyRAST::AssemblyRASTClient\n";
    }
    if ($sMajor == 0) {
        warn "AssemblyRAST::AssemblyRASTClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 AssemblyParams

=over 4



=item Description

Run individual assemblers supported by AssemblyRAST.

workspace_name - the name of the workspace for input/output
read_library_name - the name of the PE read library (SE library support in the future)
output_contig_set_name - the name of the output contigset

extra_params - assembler specific parameters
min_contig_length - minimum length of contigs to output, default 200

@optional min_contig_len
@optional extra_params


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
read_library_names has a value which is a reference to a list where each element is a string
read_library_refs has a value which is a reference to a list where each element is a string
output_contigset_name has a value which is a string
min_contig_len has a value which is an int
extra_params has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
read_library_names has a value which is a reference to a list where each element is a string
read_library_refs has a value which is a reference to a list where each element is a string
output_contigset_name has a value which is a string
min_contig_len has a value which is an int
extra_params has a value which is a reference to a list where each element is a string


=end text

=back



=head2 AssemblyOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=head2 ArastParams

=over 4



=item Description

Call AssemblyRAST.

workspace_name - the name of the workspace for input/output
read_library_name - the name of the PE read library (SE library support in the future)
output_contig_set_name - the name of the output contigset

extra_params - assembler specific parameters
min_contig_length - minimum length of contigs to output, default 200

@optional recipe
@optional assembler
@optional pipeline
@optional min_contig_len


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
read_library_names has a value which is a reference to a list where each element is a string
read_library_refs has a value which is a reference to a list where each element is a string
output_contigset_name has a value which is a string
recipe has a value which is a string
assembler has a value which is a string
pipeline has a value which is a string
min_contig_len has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
read_library_names has a value which is a reference to a list where each element is a string
read_library_refs has a value which is a reference to a list where each element is a string
output_contigset_name has a value which is a string
recipe has a value which is a string
assembler has a value which is a string
pipeline has a value which is a string
min_contig_len has a value which is an int


=end text

=back



=cut

package AssemblyRAST::AssemblyRASTClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
