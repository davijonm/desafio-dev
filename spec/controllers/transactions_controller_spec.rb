require 'rails_helper'

RSpec.describe TransactionController, type: :controller do

  describe "POST #create" do
    let(:file) { fixture_file_upload("CNAB.txt", "text/plain") }

    context "quando o arquivo esta presente e o processamento é bem sucedido" do
      before do
        allow_any_instance_of(ProcessCnabService).to receive(:process_file)
          .and_return({ success: true })
      end

      it "redireciona para root_path com notice" do
        post :create, params: { file: file }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Arquivo processado com sucesso!")
      end
    end

    context "quando o arquivo esta presente mas o processamento falha" do
      before do
        allow_any_instance_of(ProcessCnabService).to receive(:process_file)
          .and_return({ success: false, error: "Processing error" })
      end

      it "renderiza o template new e define flash alert" do
        post :create, params: { file: file }
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq("Processing error")
      end
    end

    context "quando o arquivo nao é enviado" do
      it "renderiza o template new e define flash alert" do
        post :create, params: {}
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq("Por favor, selecione um arquivo.")
      end
    end
  end

  describe "GET #index" do
    before do
      # cria um TransactionType e algumas transacoes ppara teste
      transaction_type = create(:transaction_type, code: 1, description: "Venda", nature: "Entrada", sign: "+")
      3.times do |i|
        create(:transaction,
          transaction_type: transaction_type,
          date: Date.today - i.days,
          value: 100.0,
          cpf: "12345678901",
          card: "123456789012",
          time: "120000",
          store_owner: "Owner",
          store_name: "Loja A"
        )
      end
    end

    it "atribui @transactions e @store_totals" do
      get :index
      expect(assigns(:transactions)).to be_present
      expect(assigns(:store_totals)).to be_present
    end

    it "ordena as transacoes por data de forma decrescente por padrao" do
      get :index
      transactions = assigns(:transactions)
      expect(transactions.first.date).to be >= transactions.last.date
    end

    it "permite ordenação via params" do
      get :index, params: { sort: "value", direction: "asc" }
      transactions = assigns(:transactions)
      expect(transactions.first.value).to be <= transactions.last.value
    end
  end
end
