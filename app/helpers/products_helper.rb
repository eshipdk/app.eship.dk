module ProductsHelper



  def products_option_hash(products)
    options = {}
    for product in products
      options[product.name] = product.id
    end
    return options
  end

end
