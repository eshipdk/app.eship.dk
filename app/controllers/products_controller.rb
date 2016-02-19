class ProductsController < ApplicationController
  before_filter :authenticate_admin

  def index
    @products = Product.all
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
      redirect_to @product
    else
      render 'new'
    end
  end



  private

  def product_params
    params.require(:product).permit(:product_code)
  end

end
