var Detail = React.createClass({
  render: function() {
    return (
      <div className='inner'>
        <div className='title'>
          <div className='lead text-muted'>
            {this.props.job.klass}
          </div>
        </div>
        <div className='description'>
          {this.props.job.description}
        </div>
        <div className='info'>
          <div className='duration'>
            {this.props.job.duration}
          </div>
        </div>
      </div>
    );
  }
});
