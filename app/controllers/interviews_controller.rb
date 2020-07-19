class InterviewsController < ApplicationController
  def index
    @interviews = Interview.all
  end

  def new
  end

  def create
    name = params[:interview][:name]
    room_id = JanusClient.new.create_room(name)
    interview = Interview.create name: name, status: :pending, room_id: room_id
    InterviewToken.create interview: interview, role: :expert, code: SecureRandom.hex(4)
    InterviewToken.create interview: interview, role: :candidate, code: SecureRandom.hex(4)
    redirect_to action: :index
  end

  def show
    @token = InterviewToken.find_by code: params[:id]
    @interview = @token.interview
  end

  def destroy
    Interview.destroy params[:id]
    redirect_to action: :index
  end
end
