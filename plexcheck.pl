#!/usr/bin/perl

use strict;
use LWP::UserAgent;
use JSON;

# Initial vars and API URL
my ($url, $filename) = "";
my $plexapi = "https://plex.tv/api/downloads/1.json?channel=plexpass";

# Define the repo directories where you want to save the file
my @savedirs = (
    "/home/lanyx/public_html/subdomains/repo.lanyx.net/6/x86_64",
    "/home/lanyx/public_html/subdomains/repo.lanyx.net/7/x86_64"
);

############

my $ua = LWP::UserAgent->new;
my $response = $ua->get($plexapi);

die "Error getting Plex information. Exiting.\n" if (!$response->is_success());

# Expecting JSON here in the response from the API
my $decoded = decode_json($response->decoded_content);

foreach my $type (@{ $decoded->{'computer'}->{'Linux'}->{'releases'} }) {
    if ($type->{'label'} eq "CentOS 64-bit (RPM for CentOS 6 or newer)") {
        $url = $type->{'url'};
        ($filename) = ($url =~ /(plexmediaserver-.*x86_64.rpm)/);
    }
}

die "Couldn't retrieve file info.\n" if (!$filename || !$url);

foreach my $dir (@savedirs) {
    if (! -f "$dir/$filename") {
        print "Downloading $filename to $dir...";
        $ua->mirror($url, "$dir/$filename");
        print "Complete.\n";
        system("createrepo --update $dir");
    }
}
