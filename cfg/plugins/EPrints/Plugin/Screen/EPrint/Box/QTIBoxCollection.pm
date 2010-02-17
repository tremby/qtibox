# QTIBox
# Edshare plugin to allow QTI items to be previewed

# ------------------------------------------------------------------------------
# (c) 2010 JISC-funded EASiHE project, University of Southampton
# Licensed under the Creative Commons 'Attribution non-commercial share alike' 
# licence -- see the LICENCE file for more details
# ------------------------------------------------------------------------------

package EPrints::Plugin::Screen::EPrint::Box::QTIBoxCollection;

use EPrints::Plugin::Screen::EPrint::Box;
@ISA = ('EPrints::Plugin::Screen::EPrint::Box');

use strict;

use EPrints::Plugin::QTIBoxUtils;

sub new {
	my ($class, %params) = @_;

	my $self = $class->SUPER::new(%params);

	# Register sub-classes but not this actual class.
	if ($class ne "EPrints::Plugin::Screen::EPrint::Box") {
		$self->{appears} = [
			{
				place		=>	"summary_top",
				position	=>	1000,
			},
		];
	}

	return $self;
}

sub render {
	my ($self) = @_;
	my $session = $self->{session};
	my $eprint = $self->{processor}->{eprint};

	my $div = $session->make_element("div", "id" => "qtibox");
	# TODO: write this...

	return $div;
}

sub can_be_viewed {
	my ($self) = @_;
	my $eprint = $self->{processor}->{eprint};

	if ($eprint->get_value("type") ne "collection") {
		return 0;
	}

	# if any of the EPrints in the collection have QTI, the box should be 
	# visible. pass 1 to contains_qti to say "single items only"
	for my $eprintid(@{$eprint->get_relation_ids}) {
		if (EPrints::Plugin::QTIBoxUtils::contains_qti($self->{session}, $eprintid, 1)) {
			return 1;
		}
	}

	return 0;
}

1;
