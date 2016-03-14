class ProductsController < ApplicationController
  before_filter :authenticate_admin

  def index
    @products = Product.all.paginate(:page => params[:page], :per_page => 5)
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
  end


  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to :action => :index
    else
      render 'new'
    end
  end


  def edit
    @product = Product.find(params[:id])
  end

  def update
    product = Product.find(params[:id])
    product.update(product_params)
    redirect_to :action => :index
  end

  private

  def product_params
    params.require(:product).permit(:product_code, :name)
  end

end
