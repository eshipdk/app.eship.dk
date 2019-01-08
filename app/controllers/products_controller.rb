class ProductsController < ApplicationController
  before_filter :authenticate_admin

  def index
    @products = Product.all.paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE).order(:disabled, :name)

    if params[:transporter_id] && params[:transporter_id]!=''
      @products = @products.where(['transporter_id = ?', params[:transporter_id]])
    end
    str_filters = ['internal_name', 'name', 'product_code']
    str_filters.each do |str|
      if params[str] && params[str]!=''
        @products = @products.where([(str + ' LIKE ?'), "%#{params[str]}%"])
      end
    end

#    raise @products.to_sql.to_s
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
  end


  def create
    @product = Product.new(product_params)
    @product.original_code = @product.product_code
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
    rescue PriceConfigException => e
      flash[:error] = e.issue
      redirect_to :action => :index
      return
    end
      
    render @scheme.cost_template
  end
  
  def update_cost_scheme
    begin
      @product = Product.find params[:id]
      @scheme = @product.cost_scheme
      @scheme.handle_cost_update params
      if not @scheme.valid?
        flash[:error] = @scheme.errors.messages
      end
    rescue PriceConfigException => e
      flash[:error] = e.issue
    end
    redirect_to :action => :index
  end
  
  def edit_default_price
    @product = Product.find params[:id]
    begin
      @scheme = @product.default_price_scheme
      @scheme.build
    rescue PriceConfigException => e
      flash[:error] = e.issue
      redirect_to :action => :index
      return
    end
      
    render @scheme.default_price_template
  end
  
  def update_default_price_scheme
    begin
      @product = Product.find params[:id]
      @scheme = @product.default_price_scheme
      @scheme.handle_price_update params
      if not @scheme.valid?
        flash[:error] = @scheme.errors.messages
      end
    rescue PriceConfigException => e
      flash[:error] = e.issue
    end
    redirect_to :action => :index
  end
  
  def default_price_scheme
    product = Product.find params[:product_id]
    user = User.find params[:id]
    if not user.holds_product product
      flash[:error] = 'User ' + user.name + ' can not access product ' + product.name
      redirect_to :action => :index
      return
    end
    begin
      product.use_default_price_scheme user
    rescue PriceConfigException => e
      flash[:error] = e.issue
      redirect_to :controller => :users, :action => :edit_products
      return
    end
    redirect_to :back
  end

  def cargoflux_price_scheme
    product = Product.find params[:product_id]
    user = User.find params[:id]
    if not user.holds_product product
      flash[:error] = 'User ' + user.name + ' can not access product ' + product.name
      redirect_to :action => :index
      return
    end
    begin
      scheme = product.price_scheme user
      scheme.use_cargoflux_prices
    rescue PriceConfigException => e
      flash[:error] = e.issue
      redirect_to :controller => :users, :action => :edit_products
      return
    end    
    redirect_to :back
  end
  
  def edit_price_scheme
    @product = Product.find params[:product_id]
    @user = User.find params[:id]
    if not @user.holds_product @product
      flash[:error] = 'User ' + @user.name + ' can not access product ' + @product.name
      redirect_to :action => :index
      return
    end
    begin
      @scheme = @product.price_scheme @user
    rescue PriceConfigException => e
      flash[:error] = e.issue
      redirect_to :controller => :users, :action => :edit_products
      return
    end
    render @scheme.price_template
  end

  def update_price_scheme
    begin
      @product = Product.find params[:product_id]
      @user = User.find params[:id]
      if not @user.holds_product @product
        flash[:error] = 'User ' + @user.name + ' can not access product ' + @product.name
        redirect_to :action => :index
        return
      end
      @scheme = @product.price_scheme @user
      @scheme.handle_price_update params
    rescue PriceConfigException => e
      flash[:error] = e.issue
    end
    redirect_to :controller => :users, :action => :edit_products
  end

  private

  def product_params
    params.require(:product).permit(:product_code, :name, :tracking_url_prefix,
                                    :taxed, :has_parcelshops, :disabled,
                                    :find_parcelshop_url, :return_product_id, :is_import,
                                    :transporter_id, :internal_name)
  end

end
