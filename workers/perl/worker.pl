use strict;
use warnings;
$| = 1;

while (my $line = <STDIN>) {
    if ($line =~ /"type":"HELLO"/) {
        print "{\"type\":\"WELCOME\",\"protocol\":\"ofp/1\",\"workerId\":\"perl-regex-01\",\"language\":\"perl\",\"runtimeVersion\":\"git-perl\",\"workerVersion\":\"0.1.0\",\"status\":\"ready\"}\n";
        print "{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"perl-regex-01\",\"language\":\"perl\",\"runtimeVersion\":\"git-perl\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"text.regex\"}]}\n";
    } elsif ($line =~ /"type":"REGISTER_ACK"/) {
        next;
    } elsif ($line =~ /"type":"JOB_START"/) {
        if ($line !~ /"capability":"text.regex"/) {
            print "{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}\n";
            next;
        }
        my ($job) = $line =~ /"jobId":"([^"]+)"/;
        my ($text) = $line =~ /"text":"([^"]*)"/;
        my ($pattern) = $line =~ /"pattern":"([^"]*)"/;
        print "{\"type\":\"JOB_ACCEPTED\",\"jobId\":\"$job\",\"status\":\"running\"}\n";
        print "{\"type\":\"JOB_LOG\",\"jobId\":\"$job\",\"severity\":\"info\",\"message\":\"starting text.regex\"}\n";
        my $count = 0;
        while ($text =~ /$pattern/g) {
            $count++;
        }
        print "{\"type\":\"JOB_RESULT\",\"jobId\":\"$job\",\"output\":{\"matches\":$count}}\n";
    } elsif ($line =~ /"type":"JOB_CANCEL"/) {
        my ($job) = $line =~ /"jobId":"([^"]+)"/;
        $job = "job-unknown" unless defined $job;
        print "{\"type\":\"JOB_CANCELLED\",\"jobId\":\"$job\",\"status\":\"cancelled\"}\n";
    } elsif ($line =~ /"type":"SHUTDOWN"/) {
        print "{\"type\":\"SHUTDOWN_ACK\",\"workerId\":\"perl-regex-01\",\"status\":\"stopped\"}\n";
        last;
    }
}
