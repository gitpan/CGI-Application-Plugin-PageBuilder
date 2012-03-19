
use Module::Build;
my $build = Module::Build->new(
	module_name => 'CGI::Application::Plugin::PageBuilder',
	license => 'perl',
	requires => {
		CGI::Application    => '4',
	    Test::Pod::Coverage => '0',
    },
);

$build->create_build_script();

