class TransportersController < ApplicationController
  before_filter :authenticate_admin

  def index
    @transporters = Transporter.all.paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE).order(:name)
  end

  def show
    @transporter = Transporter.find(params[:id])
  end

  def new
    @transporter = Transporter.new
  end


  def create
    @transporter = Transporter.new(transporter_params)    
    if @transporter.save
      redirect_to :action => :index
    else
      render 'new'
    end
  end


  def edit
    @transporter = Transporter.find(params[:id])
  end

  def update
    transporter = Transporter.find(params[:id])
    transporter.update(transporter_params)
    redirect_to :action => :index
  end


  private

  def transporter_params
    params.require(:transporter).permit(:name)
  end

end
