var List = React.createClass({
  render: function() {
    var cardNodes = this.props.jobs.map(function (job) {
      return <Card key={ job.id } job={ job } />
    });

    return (
      <div className="card-list">
        { cardNodes }
      </div>
    )
  }
});
