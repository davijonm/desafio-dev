class TransactionsController < ApplicationController
  before_action :authenticate_user!

  def new
  end

  def create
    if params[:file].present?
      # processa o arquivo CNAB utilizando o service
      result = ProcessCnabService.new(params[:file]).process_file

      if result[:success]
        flash[:notice] = "Arquivo processado com sucesso!"
      else
        flash[:alert] = "Ops, há algo de errado com o arquivo."
      end
    else
      flash[:alert] = "Por favor, selecione um arquivo."
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("turbo_redirect", partial: "shared/turbo_redirect", locals: { path: root_path })
      end
      format.html { redirect_to root_path }
    end
  end

  def index
    transactions = Transaction.joins(:transaction_type)

    @transactions = transactions.page(params[:page]).per(11)

    if params[:sort].present? && params[:direction].present?
      @transactions = @transactions.order("#{params[:sort]} #{params[:direction]}")
    else
      @transactions = @transactions.order(date: :desc)
    end

    transactions_by_store = Transaction.all.group_by(&:store_name)

    @store_totals = transactions_by_store.map do |store_name, transactions|
      total_balance = transactions.sum(&:value)
      { store_name: store_name, total_balance: total_balance }
    end
  end

end
