# QTIBox
# Edshare plugin to allow QTI items to be previewed

# ------------------------------------------------------------------------------
# (c) 2010 JISC-funded EASiHE project, University of Southampton
# Licensed under the Creative Commons 'Attribution non-commercial share alike' 
# licence -- see the LICENCE file for more details
# ------------------------------------------------------------------------------

package EPrints::Plugin::QTIBoxUtils;

sub new {
}

sub is_qti {
	my ($xml, $singleonly) = @_;
	my $doc = eval { EPrints::XML::parse_xml_string($xml); };
	if ($@) {
		my $err = $@;
		$err =~ s# at /.*##;
		return 0;
	}
	if ($doc->getDocumentElement()->getTagName() eq "assessmentItem") {
		return 1;
	}
	if (!$singleonly && $doc->getDocumentElement()->getTagName() eq "assessmentTest") {
		return 1;
	}
	return 0;
}

sub contains_qti {
	my ($session, $eprintid, $singleonly) = @_;
	my $eprint = new EPrints::DataObj::EPrint($session, $eprintid);
	if (!defined($eprint)) {
		return 0;
	}

	my @documents = $eprint->get_all_documents();

	if (!scalar @documents) {
		return 0;
	}
	my $document = $documents[0];

	if ($document->get_value("main") =~ /.zip$/i) {
		my $foundqti = 0;
		my $zip = Archive::Zip->new($document->local_path() . "/" . $document->get_value("main"));
		my $manifests = $zip->membersMatching('imsmanifest.xml');
		if ($manifests == 0) {
			return 0;
		}
		my @xmlfiles = $zip->membersMatching('.*\.xml');
		foreach (@xmlfiles) {
			if ($_->fileName() eq "imsmanifest.xml") {
				next;
			}
			my $xml = $zip->contents($_);
			if (is_qti($xml, $singleonly)) {
				$foundqti = 1;
				last;
			}
		}
		if (!$foundqti) {
			return 0;
		}
	} elsif ($document->get_value("main") =~ /.xml$/i) {
		open(FILE, $document->local_path() . "/" . $document->get_value("main")) or die "Couldn't open file: $!";
		my $xml = join("", <FILE>);
		close FILE;
		if (!is_qti($xml, $singleonly)) {
			return 0;
		}
	} else {
		return 0;
	}

	return 1;
}

1;
