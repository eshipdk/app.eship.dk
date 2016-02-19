module ProductsHelper



  def products_option_hash(products)
    options = {}
    for product in products
      options[product.product_code] = product.id
    end
    return options
  end

end
