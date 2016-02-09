module RocketJobMissionControl
  module WorkersHelper
    def worker_counts_by_state(state)
      RocketJob::Worker.counts_by_state.fetch(state.downcase.to_sym, 0)
    end

    def worker_icon(worker)
      state =
        if worker.zombie?
          'zombie'
        else
          worker.state
        end
      state_icon(state)
    end

    def worker_card_class(worker)
      if worker.zombie?
        'callout-zombie'
      else
        map = {
          running:  'callout-success',
          paused:   'callout-warning',
          stopping: 'callout-alert',
        }
        map[worker.state] || 'callout-info'
      end
    end
  end
end
