# frozen_string_literal: true
class CatalogController < ApplicationController

  include Blacklight::Catalog
  include Blacklight::Marc::Catalog

  #ERJ https://github.com/projectblacklight/blacklight/wiki/Adding-new-document-actions
  #, if: :display_scan_metadata?

  def is_scan?(field_config,doc)
    return true if doc[:format] == "images"
    return false if doc[:format] == "texts"
  end

  def is_object?(field_config,doc)
    return true if doc[:format] == "images"
    return false if doc[:format] == "texts"
  end



  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10,
      fl: '*'
    }

    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    #config.default_document_solr_params = {
    #  qt: 'document',
    #  ## These are hard-coded in the blacklight 'document' requestHandler
    #  # fl: '*',
    #  # rows: 1,
    #  # q: '{!term f=id v=$id}'
    #}

    # solr field configuration for search results/index views
    #https://github.com/projectblacklight/blacklight/wiki/Configuration---Results-View
    config.index.title_field = 'label_s'
    config.index.display_type_field = 'format'
    #config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr field configuration for document/show views
    #config.show.title_field = 'title_display'
    #config.show.title_field = 'label_s'
    #config.show.display_type_field = 'format'
    #config.show.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

    config.add_facet_field 'object_type_s', label: 'Type', :collapse => false, sort: 'alpha'
    config.add_facet_field 'subject_topic_facet', label: 'Subject (Images)', :limit => 100, sort: 'alpha'
    config.add_facet_field 'csn_sm', label: 'Current Scientific Name (Images)', :limit => 100, sort: 'alpha'
    config.add_facet_field 'cvn_sm', label: 'Current Vernacular Name (Images)', :limit => 100, sort: 'alpha'
    config.add_facet_field 'hsn_sm', label: 'Historic Scientific Name (Images)', :limit => 100, sort: 'alpha'
    config.add_facet_field 'hvn_sm', label: 'Historic Vernacular Name (Images)', :limit => 100, sort: 'alpha'
    config.add_facet_field 'author_display_facet', label: 'Author (Images)', :limit => 100, sort: 'alpha'
    config.add_facet_field 'gnrd_sm', label: 'Scientific Name (Texts & Images)', :limit => 50, sort: 'alpha'
    config.add_facet_field 'locations_sm', label: 'Location (Texts & Images)', :limit => 100, helper_method: 'remove_ycba', sort: 'alpha'
    config.add_facet_field 'has_scan_s', label: 'Scan Available (Texts)', sort: 'alpha'
    config.add_facet_field 'subject_s', label: 'Notebook Header (Texts)', :limit => 100, sort: 'alpha'
    #config.add_facet_field 'scan_s', label: 'Scan Facet', :limit => 100
    config.add_facet_field 'book_s', label: 'Notebook (Texts)', sort: 'index', sort: 'alpha'
    config.add_facet_field 'author_s', label: 'Notetaker (Texts)', sort: 'alpha'


    config.add_facet_field 'scan_author_sm', label: 'People (Texts & Images)', :limit => 100, sort: 'alpha'
    #config.add_facet_field 'author_display', label: 'Artist (Images)' #reinxed into scan_author_sm (even though not scan)
    config.add_facet_field 'scan_part_of_s', label: 'Container', sort: 'alpha' #none?
    config.add_facet_field 'scan_location_s', label: 'Category', sort: 'alpha' #none?

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    #config.add_index_field 'label_s', label: 'Label'
    #config.add_index_field 'title_display', label: 'Title'
    config.add_index_field 'subject_topic_facet', label: 'Subject'
    config.add_index_field 'gnrd_sm', label: 'Scientific Name'
    config.add_index_field 'locations_sm', label: 'Location'
    config.add_index_field 'scan_author_sm', label: 'Artist'
    config.add_index_field 'subject_s', label: 'Notebook Header'

    #config.add_index_field 'entries_t', label: 'Description', helper_method: 'render_markdown'


    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'id', label: 'ID'
    config.add_show_field 'title_display', label: 'Title'
    config.add_show_field 'label_s', label: 'Label'
    config.add_show_field 'locations_sm', label: 'Location', link_to_search: true
    config.add_show_field 'scan_author_sm', label: 'Artist', link_to_search: true
    config.add_show_field 'scan_sm', label: 'Related Scan', helper_method: 'render_scan_as_link'
    #config.add_show_field 'gnrd_sm', link_to_search: true, label: 'Scientific Name (GNRD)'
    config.add_show_field 'gnrd_sm', label: 'Scientific Name (GNRD)', helper_method: 'list_gnrd_as_link'
    config.add_show_field 'csn_t', label: 'Current Sci Attrib', helper_method: 'list_multivalued'
    config.add_show_field 'cvn_t', label: 'Current Vern Attrib', helper_method: 'list_multivalued'
    config.add_show_field 'hsn_t', label: 'Historical Sci Attrib', helper_method: 'list_multivalued'
    config.add_show_field 'hvn_t', label: 'Historial Vern Attrib', helper_method: 'list_multivalued'
    config.add_show_field 'csn_sm', label: 'Current Sci Facet', helper_method: 'render_csn_as_link'
    config.add_show_field 'cvn_sm', label: 'Current Vern Facet', helper_method: 'render_cvn_as_link'
    config.add_show_field 'hsn_sm', label: 'Historical Sci Facet', helper_method: 'render_hsn_as_link'
    config.add_show_field 'hvn_sm', label: 'Historial Vern Facet', helper_method: 'render_hvn_as_link'
    config.add_show_field 'notes_t', label: 'Identification Notes', helper_method: 'list_multivalued'
    config.add_show_field 'sources_t', label: 'Identification Sources', helper_method: 'list_multivalued'
    config.add_show_field 'subject_s', label: 'Notebook Header', link_to_search: true, if: :is_object?
    config.add_show_field 'entries_t', label: 'Description', helper_method: 'render_markdown'
    config.add_show_field 'subject_topic_s', label: 'Scan Subject', link_to_search: true, if: :is_scan?
    config.add_show_field 'part_of_s', label: 'Container', link_to_search: true, if: :is_scan?
    config.add_show_field 'recto_s', label: 'Recto', helper_method: 'make_html_safe', if: :is_scan?
    config.add_show_field 'verso_s', label: 'Verso', helper_method: 'make_html_safe', if: :is_scan?
    config.add_show_field 'photo_s', label: 'Photo', helper_method: 'make_html_safe', if: :is_scan?
    config.add_show_field 'institutional_stamp_s', label: 'Stamp', helper_method: 'make_html_safe'
    config.add_show_field 'object_type_s', label: 'Notebook Contents', helper_method: 'render_entries', if: :is_scan?

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields'


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
        qf: '$title_qf',
        pf: '$title_pf'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_local_parameters = {
        qf: '$author_qf',
        pf: '$author_pf'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = {
        qf: '$subject_qf',
        pf: '$subject_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    #config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', label: 'relevance'
    #config.add_sort_field 'pub_date_sort desc, title_sort asc', label: 'year'
    #config.add_sort_field 'author_sort asc, title_sort asc', label: 'author'
    #config.add_sort_field 'title_sort asc, pub_date_sort desc', label: 'title'
    config.add_sort_field 'score desc', label: 'relevance'
    config.add_sort_field 'id asc', label: 'id'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'

  end
end
