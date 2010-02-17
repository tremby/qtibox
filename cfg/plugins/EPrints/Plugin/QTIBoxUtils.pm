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

# return 0 if not qti
# return 1 if assessment item
# return 2 if assessment test
sub is_qti {
	my ($xml) = @_;
	my $doc = eval { EPrints::XML::parse_xml_string($xml); };
	if ($@) {
		my $err = $@;
		$err =~ s# at /.*##;
		return 0;
	}
	if ($doc->getDocumentElement()->getTagName() eq "assessmentItem") {
		return 1;
	}
	if ($doc->getDocumentElement()->getTagName() eq "assessmentTest") {
		return 2;
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
			my $type = is_qti($xml, $singleonly);
			if ($type == 1) {
				$foundqti = 1;
			} elsif ($type == 2) {
				if ($singleonly) {
					# found an assessment test but we're only accepting single 
					# items. return 0
					return 0;
				}
				$foundqti = 1;
			}
		}
		if (!$foundqti) {
			return 0;
		}
		return 1;
	}

	if ($document->get_value("main") =~ /.xml$/i) {
		open(FILE, $document->local_path() . "/" . $document->get_value("main")) or die "Couldn't open file: $!";
		my $xml = join("", <FILE>);
		close FILE;
		my $type = is_qti($xml, $singleonly);
		if (!$singleonly && $type || $singleonly && $type == 1) {
			return 1;
		}
	}

	return 0;
}

1;
