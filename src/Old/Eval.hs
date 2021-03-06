module Old.Eval (
  runEval,

  TermEnv,
  emptyTmenv
) where

import Old.Syntax

import Control.Monad.Identity
import qualified Data.Map as Map

data Value
  = VInt Integer
  | VBool Bool
  | VClosure String Expr TermEnv

type TermEnv = Map.Map String Value
type Interpreter t = Identity t

emptyTmenv :: TermEnv
emptyTmenv = Map.empty

instance Show Value where
  show (VInt n) = show n
  show (VBool n) = show n
  show VClosure{} = "<<closure>>"

eval :: TermEnv -> Expr -> Interpreter Value
eval env expr = case expr of
  Lit (LInt k)  -> return $ VInt k
  Lit (LBool k) -> return $ VBool k

  Var x -> do
    let Just v = Map.lookup x env
    return v

  Lam x body ->
    return (VClosure x body env)

  Let x e body -> do
    e' <- eval env e
    let nenv = Map.insert x e' env
    eval nenv body

  If cond tr fl -> do
    br <- eval env cond
    let VBool v = br
    if v
    then eval env tr
    else eval env fl

  App fun arg -> do
    result <- eval env fun
    let VClosure x body clo = result
    argv <- eval env arg
    let nenv = Map.insert x argv clo
    eval nenv body

  Op op a b -> do
    a'' <- eval env a
    b'' <- eval env b
    let VInt a' = a''
    let VInt b' = b''
    return $ (binop op) a' b'

  Fix e ->
    eval env (App e (Fix e))

binop :: Binop -> Integer -> Integer -> Value
binop Add a b = VInt $ a + b
binop Mul a b = VInt $ a * b
binop Sub a b = VInt $ a - b
binop Eql a b = VBool $ a == b

runEval :: TermEnv -> String -> Expr -> (Value, TermEnv)
runEval env nm ex =
  let res = runIdentity (eval env ex) in
  (res, Map.insert nm res env)
