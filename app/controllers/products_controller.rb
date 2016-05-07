class ProductsController < ApplicationController
  before_filter :authenticate_admin

  def index
    @products = Product.all.paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
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


  def edit_cost
    @product = Product.find params[:id]
    begin
      @scheme = @product.cost_scheme
      @scheme.build
    rescue Exception => e
      flash[:error] = e.to_s
      redirect_to :action => :index
      return
    end
      
    render @scheme.cost_template
  end
  
  def update_cost_scheme
    @product = Product.find params[:id]
    @scheme = @product.cost_scheme
    @scheme.handle_cost_update params
    if not @scheme.valid?
      flash[:error] = @scheme.errors.messages
    end
    redirect_to :action => :index
  end
  
  def edit_price_scheme
    @product = Product.find params[:product_id]
    @user = User.find params[:id]
    if not @user.holds_product @product
      flash[:error] = 'User ' + @user.email + ' can not access product ' + @product.name
      redirect_to :action => :index
      return
    end
    begin
      @scheme = @product.price_scheme @user
    rescue Exception => e
      flash[:error] = e.to_s
      redirect_to :controller => :users, :action => :edit_products
      return
    end
    render @scheme.price_template
  end

  def update_price_scheme
    @product = Product.find params[:product_id]
    @user = User.find params[:id]
    if not @user.holds_product @product
      flash[:error] = 'User ' + @user.email + ' can not access product ' + @product.name
      redirect_to :action => :index
      return
    end
    @scheme = @product.price_scheme @user
    @scheme.handle_price_update params
    redirect_to :controller => :users, :action => :edit_products
  end

  private

  def product_params
    params.require(:product).permit(:product_code, :name)
  end

end
