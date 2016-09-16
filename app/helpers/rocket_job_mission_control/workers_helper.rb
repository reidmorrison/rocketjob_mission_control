module RocketJobMissionControl
  module WorkersHelper
    def worker_counts_by_state(state)
      case state
      when 'Zombie'
        worker_count = 0
        RocketJob::Worker.each { |worker| worker_count += 1 if worker.zombie? }
        worker_count
      else
        RocketJob::Worker.counts_by_state.fetch(state.downcase.to_sym, 0)
      end
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
