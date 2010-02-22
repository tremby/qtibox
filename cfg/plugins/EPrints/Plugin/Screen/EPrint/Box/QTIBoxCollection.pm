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
	my $collection = $self->{processor}->{eprint};

	my $div = $session->make_element("div", "id" => "qtibox_eprint_" . $collection->get_id());
	$div->appendChild(my $ul = $session->make_element("ul"));
	$ul->appendChild(my $li = $session->make_element("li"));
	$li->appendChild($session->make_element("input",
		"class"		=>	"ep_form_action_button",
		"type"		=>	"button",
		"onclick"	=>	"qtibox_playitems(" . $collection->get_id() . ")",
		"value"		=>	"Play QTI items together as a test in an embedded frame",
	));
	$ul->appendChild($li = $session->make_element("li"));
	$li->appendChild(my $a = $session->make_element("a",
		"href"		=>	"/cgi/qtibox_playitems?collectionid=" . $collection->get_id(),
		"target"	=>	"_blank",
	));
	$a->appendChild($session->make_text("Play QTI items together as a test in a new window"));

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
