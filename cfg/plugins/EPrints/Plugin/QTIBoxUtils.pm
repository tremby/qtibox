# QTIBox
# Edshare plugin to allow QTI items to be previewed

# ------------------------------------------------------------------------------
# (c) 2010 JISC-funded EASiHE project, University of Southampton
# Licensed under the Creative Commons 'Attribution non-commercial share alike' 
# licence -- see the LICENCE file for more details
# ------------------------------------------------------------------------------

package EPrints::Plugin::QTIBoxUtils;
use Archive::Zip;

sub new {
}

# given XML,
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

# return 1 if the given EPrint contains QTI
# takes an session, EPrint id and a number
#	1 if only single QTI files and single-item content packages are allowed
#	0 if any QTI is allowed
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
		open(FILE, $document->local_path() . "/" . $document->get_value("main")) or die("qtibox: error opening file: $!");
		my $xml = join("", <FILE>);
		close FILE;
		my $type = is_qti($xml, $singleonly);
		if (!$singleonly && $type || $singleonly && $type == 1) {
			return 1;
		}
	}

	return 0;
}

# return XML from an EPrints document containing QTI
# parameters are an EPrints document object and a number
#	1 for assessmentItem XML
#	2 for assessmentTest XML
# returns the requested XML or undef if it's not found. when looking for an 
# assessmentItem, undef is also returned if there is more than one (it's not a 
# single-item content package)
sub qti_get_xml {
	my ($doc, $type) = @_;

	if ($type != 1 && $type != 2) {
		die("qtibox: expected 1 or 2 as second argument, got '$type'\n");
	}

	if ($doc->get_value("main") =~ /\.xml$/) {
		# it's XML. check if it's what we're looking for
		open my $fh, '<', $doc->local_path() . "/" . $doc->get_value("main") or die("qtibox: error opening file: $!");
		my $data = do { local $/; <$fh> };

		if (is_qti($data) == $type) {
			return $data;
		}
		return undef;
	}

	if ($doc->get_value("main") =~ /\.zip$/) {
		# it's a zip file. could be a content package

		my $zip = Archive::Zip->new($doc->local_path() . "/" . $doc->get_value("main"));
		my $manifestxml = $zip->contents("imsmanifest.xml");
		if (!defined $manifestxml) {
			print STDERR "qtibox: error getting manifest\n";
			return undef;
		}
		my $dom = eval {
			EPrints::XML::parse_xml_string($manifestxml);
		};
		if ($@) {
			my $err = $@;
			$err =~ s# at /.*##;
			print STDERR "qtibox: error parsing manifest XML\n";
			return undef;
		}

		# resources
		my $resources = $dom->getElementsByTagName("resource");
		if ($type == 1 && $resources->getLength > 1) {
			# want a single item but there is more than one
			return undef;
		} elsif ($resources->getLength == 0) {
			print STDERR "qtibox: no resources found\n";
			return undef;
		}

		# count tests and items
		my @tests = ();
		my @items = ();
		for (my $i = 0; $i < $resources->getLength; $i++) {
			my $t = $resources->item($i)->getAttributeNode("type")->getValue;
			if ($t =~ /^imsqti_item_/) {
				push(@items, $i);
			} elsif ($t =~ /^imsqti_(test|assessment)_/) {
				push(@tests, $i);
			}
		}

		my @array;
		if ($type == 1) {
			@array = @items;
		} else {
			@array = @tests;
		}

		if (scalar(@array) != 1) {
			print STDERR "qtibox: wanted an assessment item or test, expected 1 to be present, found " . scalar($array) . "\n";
			return undef;
		}

		# return the XML it points to
		my $xmlfilename = $resources->item(pop(@array))->getAttributeNode("href")->getValue;
		my $xml = $zip->contents($xmlfilename);
		if (!defined $xml) {
			print STDERR "qtibox: error getting contents of file '$xmlfilename'\n";
			return undef;
		}
		return $xml;
	}

	return undef;
}

1;
