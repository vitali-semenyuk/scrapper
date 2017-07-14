require_relative 'null_logger'
require_relative 'page'

class Scrapper
  def initialize(url, options = {})
    @url = url
    @page_class = options[:list_page_class] || Page
    @pagination_parameter = options[:pagination_parameter] || 'p'
    @logger = options[:logger] || NullLogger.new
    @options = options
  end

  def parse
    @logger.info "Start processing url: #{@url}"

    start_page = @page_class.new(@url, @options)

    pages_quantity = start_page.parse.respond_to?(:pages_count) ? start_page.pages_count : 0

    return [start_page.payload] unless pages_quantity > 1

    @logger.info "Found #{pages_quantity - 1} extra pages:"

    pages = Array.new(pages_quantity) do |index|
      page_url = "#{@url.chomp('/')}/?#{@pagination_parameter}=#{index + 1}"
      @logger.info "\t#{index}: #{page_url}" unless index.zero?
      @page_class.new(page_url, @options)
    end

    payload = pages.drop(1).map { |page| page.parse.payload }

    ([start_page.payload] + payload).flatten
  end
end