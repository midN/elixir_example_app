defmodule Stockman.User do
  use Stockman.Web, :model
  alias Stockman.Repo
  alias Stockman.Convert
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string
    has_many :converts, Convert

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, ~w(email), [])
    |> unique_constraint(:email)
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
  end

  def registration_changeset(struct, params \\ %{}) do
    struct
    |> changeset(params)
    |> cast(params, ~w(password), [])
    |> validate_confirmation(:password)
    |> validate_length(:password, min: 6)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
      _ ->
        changeset
    end
  end

  def find_and_confirm_pw(email, pass) do
    user = Repo.get_by(__MODULE__, email: email)
    cond do
      user && checkpw(pass, user.password_hash) ->
        {:ok, user}
      user ->
        {:error, :unauthorized}
      true ->
        dummy_checkpw()
        {:error, :not_found}
    end
  end
end
