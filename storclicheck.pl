#!/usr/bin/perl

use strict;
use LWP::UserAgent;
use File::Copy;

my $storcliurl = "http://www.avagotech.com/products/server-storage/raid-controllers/megaraid-sas-9266-8i#downloads";
my $storclidlurl = "http://docs.avagotech.com/docs-and-downloads/docs-and-downloads/raid-controllers/raid-controllers-common-files";

my @savedirs = (
    "/home/lanyx/public_html/subdomains/repo.lanyx.net/6/x86_64",
    "/home/lanyx/public_html/subdomains/repo.lanyx.net/7/x86_64"
);

my $ua = LWP::UserAgent->new;
my $response = $ua->get($storcliurl);

my ($url) = ($response->decoded_content =~ /(http:\/\/docs\.\S+\.com\/docs\/[\d\.]+_StorCLI\.zip)/);
my ($filename) = ($url =~ /([\d\.]+_StorCLI\.zip)/);

die "Couldn't retrieve url or filename.\n" if (!$url || !$filename);

if (! -f $filename) {
    $ua->mirror("$storclidlurl/$filename", $filename);
    system("unzip -oj $filename 'storcli_all_os/Linux/*.rpm'");
    my $rpm = glob "storcli-*.noarch.rpm";

    foreach my $dir (@savedirs) {
        if (! -f "$dir/$rpm") {
            copy($rpm, "$dir/$rpm") or die "Something went wrong with copying the RPM.\n";
            system("createrepo --update $dir");
        }
    }
    unlink $rpm;
}
