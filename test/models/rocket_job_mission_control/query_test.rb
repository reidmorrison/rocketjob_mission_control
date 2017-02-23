require_relative '../../test_helper'

class QueryTest < Minitest::Test

  class NoopJob < RocketJob::Job
    def perform(record)
      # noop
    end
  end

  describe RocketJobMissionControl::Query do
    before do
      @jobs = (1..10).collect { |i| NoopJob.create(description: "Job #{i}") }
    end

    after do
      NoopJob.delete_all
    end

    describe '#query' do
      it 'sorts ascending by id' do
        count       = 0
        previous_id = nil
        RocketJobMissionControl::Query.new(NoopJob.all, _id: 1).query.each do |job|
          assert(previous_id < job.id, "Wrong sort order. #{previous_id} < #{job.id}") if previous_id
          previous_id = job.id
          count       += 1
        end
        assert_equal @jobs.count, count
      end

      it 'sorts descending by id' do
        count       = 0
        previous_id = nil
        RocketJobMissionControl::Query.new(NoopJob.all, _id: -1).query.each do |job|
          assert(previous_id > job.id, "Wrong sort order. #{previous_id} > #{job.id}") if previous_id
          previous_id = job.id
          count       += 1
        end
        assert_equal @jobs.count, count
      end

      it 'sorts ascending by description' do
        count    = 0
        previous = nil
        RocketJobMissionControl::Query.new(NoopJob.all, description: 1).query.each do |job|
          assert(previous < job.description, "Wrong sort order. #{previous} < #{job.description}") if previous
          previous = job.description
          count    += 1
        end
        assert_equal @jobs.count, count
      end

      it 'sorts ascending by id with a search' do
        q = RocketJobMissionControl::Query.new(NoopJob.all, description: 1)
        q.search_columns << :description
        q.search_term = 'Job 1'

        count       = 0
        previous_id = nil
        q.query.each do |job|
          assert(previous_id < job.id, "Wrong sort order. #{previous_id} < #{job.id}") if previous_id
          previous_id = job.id
          count       += 1
        end
        assert_equal 2, count
      end

      it 'paginates with sort' do
        q           = RocketJobMissionControl::Query.new(NoopJob.all, _id: 1)
        q.start     = 1
        q.page_size = 3

        count       = 0
        previous_id = nil
        q.query.each do |job|
          assert(previous_id < job.id, "Wrong sort order. #{previous_id} < #{job.id}") if previous_id
          previous_id = job.id
          count       += 1
        end
        assert_equal 3, count
      end

      it 'paginates with sort and search' do
        q = RocketJobMissionControl::Query.new(NoopJob.all, _id: 1)
        q.search_columns << :description
        q.search_term = 'Job'
        q.start       = 1
        q.page_size   = 3

        count       = 0
        previous_id = nil
        q.query.each do |job|
          assert(previous_id < job.id, "Wrong sort order. #{previous_id} < #{job.id}") if previous_id
          previous_id = job.id
          count       += 1
        end
        assert_equal 3, count
      end

    end

    describe '#count' do
      it 'without search' do
        assert_equal 10, RocketJobMissionControl::Query.new(NoopJob.all, description: 1).count
      end

      it 'with search and pagination' do
        q = RocketJobMissionControl::Query.new(NoopJob.all, description: 1)
        q.search_columns << :description
        q.search_term = 'Job 1'
        # Pagination should be ignored
        q.start       = 1
        q.page_size   = 1
        assert_equal 2, q.count
      end
    end

    describe '#unfiltered_count' do
      it 'without search' do
        assert_equal 10, RocketJobMissionControl::Query.new(NoopJob.all, description: 1).unfiltered_count
      end

      it 'with search and pagination' do
        q = RocketJobMissionControl::Query.new(NoopJob.all, description: 1)
        q.search_columns << :description
        q.search_term = 'Job 1'
        # Pagination should be ignored
        q.start       = 1
        q.page_size   = 3
        assert_equal 10, q.unfiltered_count
      end
    end

  end
end
