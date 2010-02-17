# QTIBox
# Edshare plugin to allow QTI items to be previewed

# ------------------------------------------------------------------------------
# (c) 2010 JISC-funded EASiHE project, University of Southampton
# Licensed under the Creative Commons 'Attribution non-commercial share alike' 
# licence -- see the LICENCE file for more details
# ------------------------------------------------------------------------------

package EPrints::Plugin::Screen::EPrint::Box::QTIBox;

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

	my @documents = $eprint->get_all_documents();
	if (!scalar @documents) {
		return 0;
	}
	my $document = $documents[0];

	my $div = $session->make_element("div", "id" => "qtibox_document_" . $document->get_id());
	my $button = $session->make_element("input",
		"class"		=>	"ep_form_action_button",
		"type"		=>	"button",
		"onclick"	=>	"qtibox_playitem(" . $document->get_id() . ")",
		"value"		=>	"Play QTI item",
	);
	$div->appendChild($button);

	return $div;
}

sub can_be_viewed {
	my ($self) = @_;
	my $eprint = $self->{processor}->{eprint};

	return EPrints::Plugin::QTIBoxUtils::contains_qti($self->{session}, $eprint->get_id(), 0);
}

1;
