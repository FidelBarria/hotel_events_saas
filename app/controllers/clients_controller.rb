class ClientsController < ApplicationController
  PAGE_SIZE = 20

  before_action :authenticate_user!
  before_action :set_client, only: %i[show edit update destroy]

  def index
    clients = Client.order(:name, :id)
    @total_clients = clients.count
    @page = page_number(params[:page])
    @clients = clients.limit(PAGE_SIZE).offset((@page - 1) * PAGE_SIZE)
    @total_pages = [(@total_clients.to_f / PAGE_SIZE).ceil, 1].max

    @search_term = params[:q].to_s.strip
    @search_results = search_clients(@search_term) if @search_term.present?
    @search_page = page_number(params[:search_page])
    @search_total = @search_results&.count || 0
    @search_results = @search_results&.order(:name, :id)&.limit(PAGE_SIZE)&.offset((@search_page - 1) * PAGE_SIZE)
    @search_total_pages = [(@search_total.to_f / PAGE_SIZE).ceil, 1].max
  end

  def show
  end

  def new
    @client = Client.new
  end

  def edit
  end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to @client, notice: "Cliente cadastrado com sucesso."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: "Cadastro do cliente atualizado.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @client.events.exists?
      redirect_to clients_path, alert: "Este cliente já está vinculado a eventos e não pode ser excluído."
    elsif @client.destroy
      redirect_to clients_path, notice: "Cliente removido com sucesso.", status: :see_other
    else
      redirect_to clients_path, alert: @client.errors.full_messages.to_sentence
    end
  end

  private

  def set_client
    @client = Client.find(params.expect(:id))
  end

  def client_params
    params.expect(client: %i[name cnpj phone email])
  end

  def search_clients(term)
    name_query = "%#{Client.sanitize_sql_like(term)}%"
    cnpj_digits = term.gsub(/\D/, "")
    scope = Client.where("clients.name LIKE ?", name_query)
    return scope if cnpj_digits.blank?

    cnpj_query = "%#{Client.sanitize_sql_like(cnpj_digits)}%"
    Client.where("clients.name LIKE :name OR clients.cnpj LIKE :cnpj", name: name_query, cnpj: cnpj_query)
  end

  def page_number(value)
    [Integer(value, 10, exception: false) || 1, 1].max
  end
end
