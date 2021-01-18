import casadi
import tensorflow as tf

class TensorFlowEvaluator(casadi.Callback):
  def __init__(self,t_in,t_out,session, opts={}):
    """
      t_in: list of inputs (tensorflow placeholders)
      t_out: list of outputs (tensors dependeant on those placeholders)
      session: a tensorflow session
    """
    casadi.Callback.__init__(self)
    assert isinstance(t_in,list)
    self.t_in = t_in
    assert isinstance(t_out,list)
    self.t_out = t_out
    self.construct("TensorFlowEvaluator", opts)
    self.session = session
    self.refs = []

  def get_n_in(self): return len(self.t_in)
  def get_n_out(self): return len(self.t_out)

  def get_sparsity_in(self,i):
      return casadi.Sparsity.dense(*self.t_in[i].get_shape().as_list())

  def get_sparsity_out(self,i):
      return casadi.Sparsity.dense(*self.t_out[i].get_shape().as_list())

  def eval(self,arg):
    # Associate each tensorflow input with the numerical argument passed by CasADi
    d = dict((v,arg[i].toarray()) for i,v in enumerate(self.t_in))
    # Evaluate the tensorflow expressions
    ret = self.session.run(self.t_out,feed_dict=d)
    return ret

  # Vanilla tensorflow offers just the reverse mode AD
  def has_reverse(self,nadj): return nadj==1
  def get_reverse(self,nadj,name,inames,onames,opts):
    # Construct tensorflow placeholders for the reverse seeds
    adj_seed = [tf.placeholder(shape=self.sparsity_out(i).shape,dtype=tf.float64) for i in range(self.n_out())]
    # Construct the reverse tensorflow graph through 'gradients'
    grad = tf.gradients(self.t_out, self.t_in,grad_ys=adj_seed)
    # Create another TensorFlowEvaluator object
    callback = TensorFlowEvaluator(self.t_in+adj_seed,grad,self.session)
    # Make sure you keep a reference to it
    self.refs.append(callback)

    # Package it in the nominal_in+nominal_out+adj_seed form that CasADi expects
    nominal_in = self.mx_in()
    nominal_out = self.mx_out()
    adj_seed = self.mx_out()
    return casadi.Function(name,nominal_in+nominal_out+adj_seed,callback.call(nominal_in+adj_seed),inames,onames)


if __name__=="__main__":
  from casadi import *

  a = tf.placeholder(shape=(2,2),dtype=tf.float64)
  b = tf.placeholder(shape=(2,1),dtype=tf.float64)

  y = tf.matmul(tf.sin(a), b)

  with tf.Session() as session:
    f_tf = TensorFlowEvaluator([a,b], [y], session)

    a = MX.sym("a",2,2)
    b = MX.sym("a",2,1)
    y = f_tf(a,b)
    yref = mtimes(sin(a),b)

    f = Function('f',[a,b],[y])
    fref = Function('f',[a,b],[yref])

    print(f(DM([[1,2],[3,4]]),DM([[1],[3]])))
    print(fref(DM([[1,2],[3,4]]),DM([[1],[3]])))

    f = Function('f',[a,b],[jacobian(y,a)])
    fref = Function('f',[a,b],[jacobian(yref,a)])
    print(f(DM([[1,2],[3,4]]),DM([[1],[3]])))
    print(fref(DM([[1,2],[3,4]]),DM([[1],[3]])))

