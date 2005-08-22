=head1 NAME

CGI::Application::Plugin::PageBuilder - Simplifies building pages with multiple templates in CGI::Application.

=head1 SYNOPSIS

This module is built on the idea that building complex web pages with the default CGI::Application method can get to be a real mess.  I personally found it much easier to build pages from many different smaller templates than to try to create one large template.  This is especially true when displaying large sets of data from a database where you would be filling in a lot of <TMPL_VAR>s for each cell.  This module aims to make that process a little easier.

So instead of:

 sub run_mode {
 	my $self = shift;
 	my $header = $self->load_tmpl( 'header.tmpl' )->output();
 	my $html;

 	my $start = $self->load_tmpl( 'view_start.tmpl' );
 	$start->param( view_name => 'This View' );
 	$html .= $start->output();

	 my $db = MyApp::DB::Views->retrieve_all(); # Class::DBI
	 while ( my $line = $db->next() ) {
		 my $template = $self->load_tmpl( 'view_element.tmpl' );
		 $template->param( name => $line->name() );
		 $template->param( info => $line->info() );
		 $html .= $template->output();
	 }
	 $html .= $self->load_tmpl( 'view_end.tmpl' )->output();
	 $html .= $self->load_tmpl( 'footer.tmpl' )->output();
	 return $html;
 }

You can do this:

 In your CGI:App subclass:

 sub setup {
     ...
	 $self->pb_init( { header => 'header.tmpl', footer => 'footer.tmpl' } );
	 ...
 }

 sub run_mode {
  	my $self = shift;

	$self->pb_template( 'view_start.tmpl' );

 	my $db = MyApp::DB::Views->retrieve_all();
 	while( my $line = $db->next() ) {
		$self->pb_template( 'view_element.tmpl' );
		$self->pb_param( name, $line->name() );
		$self->pb_param( info, $line->info() );
 	}
	$self->pb_template( 'view_end.tmpl' );
 	return $self->pb_build();
 }

Which arguably looks much cleaner.

=head1 METHODS

=head2 pb_template

$self->pb_template( 'the_template_to_use.tmpl', ... );

Adds the template to the page and sets it as the next template to apply param to.  Any agruments past the template name are passed to HTML::Template as arguments like "die_on_bad_params => 0", etc.

=head2 pb_param

$self->pb_param( name, value );

Sets the value for the param in the template.  This applies to the last template loaded by B<pb_template()>.

=head2 pb_build

$self->pb_build();

Builds the page and returns the resulting HTML.

=head1 TODO

Passing options to L<HTML::Template> needs more testing.

=head1 AUTHOR

Clint Moore C<< <cmoore@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005, Clint Moore C<< <cmoore@cpan.org> >>.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


package CGI::Application::Plugin::PageBuilder;
$VERSION = '0.8.2';

use Carp;

use base 'Exporter';
use vars '@EXPORT';

@EXPORT = qw(
			 pb_init
			 pb_template
			 pb_param
			 pb_build
			);

sub pb_init {
	my $self = shift;
	my $options = shift;

	$self->{__PB_BUFFER} = '';
	$self->{__PB_TEMPLATE_COUNT} = 0;
	$self->{__PB_HEADER} = $options->{header} if exists( $options->{header} );
	$self->{__PB_FOOTER} = $options->{footer} if exists( $options->{footer} );
	$self->{__PB_READY} = 1;
	$self->{__PB_TEMPLATE_LIST} = ();
	$self->{__PB_TOOLBAR} = $options->{toolbar} if exists( $options->{toolbar} );
	return $self;
}

sub pb_template {
	my( $self, $template, %options ) = @_;

	$self->pb_init() unless exists $self->{__PB_READY};

	$self->{__PB__TEMPLATE_COUNT}++;
	my $status = $self->load_tmpl( $template, %options );
	push( @{ $self->{__PB_TEMPLATE_LIST} }, $status );
	return $status;
}

sub pb_build {
	my $self = shift;

	if ( exists $self->{__PB_HEADER} ) {
		$self->{__PB_BUFFER} = $self->load_tmpl( $self->{__PB_HEADER} )->output();
	}

	foreach my $template ( @{ $self->{__PB_TEMPLATE_LIST} } ) {
		$self->{__PB_BUFFER} .= $template->output();
	}

	if ( exists $self->{__PB_FOOTER} ) {
		$self->{__PB_BUFFER} .= $self->load_tmpl( $self->{__PB_FOOTER} )->output();
	}
	return $self->{__PB_BUFFER};
}

sub pb_param {
	my( $self ) = shift;
	my( $param ) = shift;

	if ( ref( $param ) eq 'HASH' ) {
		while ( my( $p, $v ) = each %{ $param } ) {
			${${ $self->{__PB_TEMPLATE_LIST} }[$#{$self->{__PB_TEMPLATE_LIST}}]}->param( $p, $v );
		}
		return;
	}

	my $value = shift;
	return undef unless( $value );

	${$self->{__PB_TEMPLATE_LIST}}[$#{@{$self->{__PB__TEMPLATE_LIST}}}]->param( $param, $value );
	return 1;
}

1;
