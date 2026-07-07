require_relative "../../test_helper"

module RocketJobMissionControl
  class AbstractDatatableTest < ActiveSupport::TestCase
    # Minimal stand-in for the view: AbstractDatatable only delegates #params to it.
    class FakeView
      attr_reader :params

      def initialize(params)
        @params = ActionController::Parameters.new(params)
      end
    end

    def build_query
      query                 = RocketJobMissionControl::Query.new(RocketJob::Job.all, _id: 1)
      query.display_columns = %w[name state]
      query
    end

    def build(params)
      AbstractDatatable.new(FakeView.new(params), build_query)
    end

    describe AbstractDatatable do
      describe "#map" do
        it "must be implemented by subclasses" do
          datatable = build({})
          assert_raises(NotImplementedError) { datatable.send(:map, Object.new) }
        end
      end

      describe "pagination params" do
        it "applies start and page size from the request" do
          datatable = build(start: "5", length: "25")

          assert_equal 5, datatable.query.start
          assert_equal 25, datatable.query.page_size
        end

        it "defaults the page size to 10" do
          datatable = build(start: "0")

          assert_equal 10, datatable.query.page_size
        end

        it "skips pagination when length is -1 (show all)" do
          datatable = build(length: "-1")

          assert_nil datatable.query.start
          assert_nil datatable.query.page_size
        end
      end

      describe "search params" do
        it "assigns the search term when present" do
          datatable = build(search: {value: "widgets"})

          assert_equal "widgets", datatable.query.search_term
        end

        it "leaves the search term unset when blank" do
          datatable = build(search: {value: ""})

          assert_nil datatable.query.search_term
        end
      end

      describe "sort params" do
        it "maps a column index and direction onto the query order" do
          datatable = build(order: {"0" => {column: "1", dir: "asc"}})

          assert_equal({"state" => "asc"}, datatable.query.order_by)
        end

        it "raises for a column index outside the display columns" do
          assert_raises(ArgumentError) do
            build(order: {"0" => {column: "9", dir: "asc"}})
          end
        end
      end
    end
  end
end
