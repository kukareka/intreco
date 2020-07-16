class InterviewsController < ApplicationController
  def index
    @interviews = Interview.all
  end

  def new
  end

  def create
    interview = Interview.create name: params[:interview][:name], status: :pending
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
