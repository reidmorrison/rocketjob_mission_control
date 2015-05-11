var Queue = React.createClass({
  getInitialState: function () {
    return {jobs: JSON.parse(this.props.jobs)};
  },

  render: function() {
    return (
      <div id='queue'>
        <div className='col-md-4 job-list'>
          <List jobs={ this.state.jobs } />
        </div>

        <div className='col-md-8 job-status'>
          <div id='job_details'>
            <Detail job={ this.state.job } />
          </div>
        </div>
      </div>
    );
  }
});
