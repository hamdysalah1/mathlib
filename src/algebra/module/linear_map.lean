/-
Copyright (c) 2020 Anne Baanen. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Nathaniel Thomas, Jeremy Avigad, Johannes Hölzl, Mario Carneiro, Anne Baanen
-/
import algebra.module.basic
import algebra.module.pi

/-!
# Linear maps and linear equivalences

In this file we define

* `linear_map R M M₂`, `M →ₗ[R] M₂` : a linear map between two R-`semimodule`s.

* `is_linear_map R f` : predicate saying that `f : M → M₂` is a linear map.

* `linear_equiv R M ₂`, `M ≃ₗ[R] M₂`: an invertible linear map

## Tags

linear map, linear equiv, linear equivalences, linear isomorphism, linear isomorphic
-/

open function
open_locale big_operators

universes u u' v w x y z
variables {R : Type u} {k : Type u'} {S : Type v} {M : Type w} {M₂ : Type x} {M₃ : Type y}
  {ι : Type z}

/-- A map `f` between semimodules over a semiring is linear if it satisfies the two properties
`f (x + y) = f x + f y` and `f (c • x) = c • f x`. The predicate `is_linear_map R f` asserts this
property. A bundled version is available with `linear_map`, and should be favored over
`is_linear_map` most of the time. -/
structure is_linear_map (R : Type u) {M : Type v} {M₂ : Type w}
  [semiring R] [add_comm_monoid M] [add_comm_monoid M₂] [semimodule R M] [semimodule R M₂]
  (f : M → M₂) : Prop :=
(map_add : ∀ x y, f (x + y) = f x + f y)
(map_smul : ∀ (c : R) x, f (c • x) = c • f x)

/-- A map `f` between semimodules over a semiring is linear if it satisfies the two properties
`f (x + y) = f x + f y` and `f (c • x) = c • f x`. Elements of `linear_map R M M₂` (available under
the notation `M →ₗ[R] M₂`) are bundled versions of such maps. An unbundled version is available with
the predicate `is_linear_map`, but it should be avoided most of the time. -/
structure linear_map (R : Type u) (M : Type v) (M₂ : Type w)
  [semiring R] [add_comm_monoid M] [add_comm_monoid M₂] [semimodule R M] [semimodule R M₂] :=
(to_fun : M → M₂)
(map_add'  : ∀x y, to_fun (x + y) = to_fun x + to_fun y)
(map_smul' : ∀(c : R) x, to_fun (c • x) = c • to_fun x)

infixr ` →ₗ `:25 := linear_map _
notation M ` →ₗ[`:25 R:25 `] `:0 M₂:0 := linear_map R M M₂

namespace linear_map

section add_comm_monoid

variables [semiring R] [add_comm_monoid M] [add_comm_monoid M₂] [add_comm_monoid M₃]

section
variables [semimodule R M] [semimodule R M₂]

instance : has_coe_to_fun (M →ₗ[R] M₂) := ⟨_, to_fun⟩

@[simp] lemma coe_mk (f : M → M₂) (h₁ h₂) :
  ((linear_map.mk f h₁ h₂ : M →ₗ[R] M₂) : M → M₂) = f := rfl


/-- Identity map as a `linear_map` -/
def id : M →ₗ[R] M :=
⟨id, λ _ _, rfl, λ _ _, rfl⟩

lemma id_apply (x : M) :
  @id R M _ _ _ x = x := rfl

@[simp, norm_cast] lemma id_coe : ((linear_map.id : M →ₗ[R] M) : M → M) = _root_.id :=
by { ext x, refl }

end

section
-- We can infer the module structure implicitly from the linear maps,
-- rather than via typeclass resolution.
variables {semimodule_M : semimodule R M} {semimodule_M₂ : semimodule R M₂}
variables (f g : M →ₗ[R] M₂)

@[simp] lemma to_fun_eq_coe : f.to_fun = ⇑f := rfl

theorem is_linear : is_linear_map R f := ⟨f.2, f.3⟩

variables {f g}

theorem coe_inj (h : (f : M → M₂) = g) : f = g :=
by cases f; cases g; cases h; refl

@[ext] theorem ext (H : ∀ x, f x = g x) : f = g :=
coe_inj $ funext H

lemma coe_fn_congr : Π {x x' : M}, x = x' → f x = f x'
| _ _ rfl := rfl

theorem ext_iff : f = g ↔ ∀ x, f x = g x :=
⟨by { rintro rfl x, refl } , ext⟩

/-- If two linear maps are equal, they are equal at each point. -/
lemma lcongr_fun (h : f = g) (m : M) : f m = g m :=
congr_fun (congr_arg linear_map.to_fun h) m

variables (f g)

@[simp] lemma map_add (x y : M) : f (x + y) = f x + f y := f.map_add' x y

@[simp] lemma map_smul (c : R) (x : M) : f (c • x) = c • f x := f.map_smul' c x

@[simp] lemma map_zero : f 0 = 0 :=
by rw [← zero_smul R, map_smul f 0 0, zero_smul]

instance : is_add_monoid_hom f :=
{ map_add := map_add f,
  map_zero := map_zero f }

/-- convert a linear map to an additive map -/
def to_add_monoid_hom : M →+ M₂ :=
{ to_fun := f,
  map_zero' := f.map_zero,
  map_add' := f.map_add }

@[simp] lemma to_add_monoid_hom_coe :
  ((f.to_add_monoid_hom) : M → M₂) = f := rfl

@[simp] lemma map_sum {ι} {t : finset ι} {g : ι → M} :
  f (∑ i in t, g i) = (∑ i in t, f (g i)) :=
f.to_add_monoid_hom.map_sum _ _

end

section

variables [semimodule R M] [semimodule R M₂] [semimodule R M₃]
variables (f : M₂ →ₗ[R] M₃) (g : M →ₗ[R] M₂)

/-- Composition of two linear maps is a linear map -/
def comp : M →ₗ[R] M₃ := ⟨f ∘ g, by simp, by simp⟩

@[simp] lemma comp_apply (x : M) : f.comp g x = f (g x) := rfl

@[norm_cast]
lemma comp_coe : (f : M₂ → M₃) ∘ (g : M → M₂) = f.comp g := rfl

@[simp] theorem comp_id : f.comp id = f :=
linear_map.ext $ λ x, rfl

@[simp] theorem id_comp : id.comp f = f :=
linear_map.ext $ λ x, rfl

theorem comp_assoc {M₄ : Type*} [add_comm_monoid M₄] [semimodule R M₄]
  (f : M →ₗ[R] M₂) (g : M₂ →ₗ[R] M₃) (h : M₃ →ₗ[R] M₄) :
  (h.comp g).comp f = h.comp (g.comp f) :=
rfl

end

variables [semimodule R M] [semimodule R M₂] [semimodule R M₃]

/-- If a function `g` is a left and right inverse of a linear map `f`, then `g` is linear itself. -/
def inverse
  (f : M →ₗ[R] M₂) (g : M₂ → M) (h₁ : left_inverse g f) (h₂ : right_inverse g f) :
  M₂ →ₗ[R] M :=
by dsimp [left_inverse, function.right_inverse] at h₁ h₂; exact
  ⟨g, λ x y, by { rw [← h₁ (g (x + y)), ← h₁ (g x + g y)]; simp [h₂] },
      λ a b, by { rw [← h₁ (g (a • b)), ← h₁ (a • g b)]; simp [h₂] }⟩

/-- The constant 0 map is linear. -/
instance : has_zero (M →ₗ[R] M₂) := ⟨⟨λ _, 0, by simp, by simp⟩⟩

instance : inhabited (M →ₗ[R] M₂) := ⟨0⟩

@[simp] lemma zero_apply (x : M) : (0 : M →ₗ[R] M₂) x = 0 := rfl

variables (f g : M →ₗ[R] M₂)

/-- The sum of two linear maps is linear. -/
instance : has_add (M →ₗ[R] M₂) :=
⟨λ f g, ⟨λ b, f b + g b, by simp [add_comm, add_left_comm], by simp [smul_add]⟩⟩

@[simp] lemma add_apply (x : M) : (f + g) x = f x + g x := rfl

/-- The type of linear maps is an additive monoid. -/
instance : add_comm_monoid (M →ₗ[R] M₂) :=
by refine {zero := 0, add := (+), ..};
   intros; ext; simp [add_comm, add_left_comm]

instance linear_map_apply_is_add_monoid_hom (a : M) :
  is_add_monoid_hom (λ f : M →ₗ[R] M₂, f a) :=
{ map_add := λ f g, linear_map.add_apply f g a,
  map_zero := rfl }

lemma add_comp (g : M₂ →ₗ[R] M₃) (h : M₂ →ₗ[R] M₃) :
  (h + g).comp f = h.comp f + g.comp f := rfl

lemma comp_add (g : M →ₗ[R] M₂) (h : M₂ →ₗ[R] M₃) :
  h.comp (f + g) = h.comp f + h.comp g := by { ext, simp }

lemma sum_apply (t : finset ι) (f : ι → M →ₗ[R] M₂) (b : M) :
  (∑ d in t, f d) b = ∑ d in t, f d b :=
(t.sum_hom (λ g : M →ₗ[R] M₂, g b)).symm

/-- `λb, f b • x` is a linear map. -/
def smul_right (f : M₂ →ₗ[R] R) (x : M) : M₂ →ₗ[R] M :=
⟨λb, f b • x, by simp [add_smul], by simp [smul_smul]⟩.

@[simp] theorem smul_right_apply (f : M₂ →ₗ[R] R) (x : M) (c : M₂) :
  (smul_right f x : M₂ → M) c = f c • x := rfl

instance : has_one (M →ₗ[R] M) := ⟨linear_map.id⟩
instance : has_mul (M →ₗ[R] M) := ⟨linear_map.comp⟩

@[simp] lemma one_app (x : M) : (1 : M →ₗ[R] M) x = x := rfl
@[simp] lemma mul_app (A B : M →ₗ[R] M) (x : M) : (A * B) x = A (B x) := rfl

@[simp] theorem comp_zero : f.comp (0 : M₃ →ₗ[R] M) = 0 :=
ext $ assume c, by rw [comp_apply, zero_apply, zero_apply, f.map_zero]

@[simp] theorem zero_comp : (0 : M₂ →ₗ[R] M₃).comp f = 0 :=
rfl

@[norm_cast] lemma coe_fn_sum {ι : Type*} (t : finset ι) (f : ι → M →ₗ[R] M₂) :
  ⇑(∑ i in t, f i) = ∑ i in t, (f i : M → M₂) :=
add_monoid_hom.map_sum ⟨@to_fun R M M₂ _ _ _ _ _, rfl, λ x y, rfl⟩ _ _

instance : monoid (M →ₗ[R] M) :=
by refine {mul := (*), one := 1, ..}; { intros, apply linear_map.ext, simp {proj := ff} }

end add_comm_monoid

section add_comm_group

variables [semiring R] [add_comm_group M] [add_comm_group M₂]
variables {semimodule_M : semimodule R M} {semimodule_M₂ : semimodule R M₂}
variables (f : M →ₗ[R] M₂)

@[simp] lemma map_neg (x : M) : f (- x) = - f x :=
f.to_add_monoid_hom.map_neg x

@[simp] lemma map_sub (x y : M) : f (x - y) = f x - f y :=
f.to_add_monoid_hom.map_sub x y

instance : is_add_group_hom f :=
{ map_add := map_add f}

end add_comm_group

end linear_map

namespace is_linear_map

section add_comm_monoid
variables [semiring R] [add_comm_monoid M] [add_comm_monoid M₂]
variables [semimodule R M] [semimodule R M₂]
include R

/-- Convert an `is_linear_map` predicate to a `linear_map` -/
def mk' (f : M → M₂) (H : is_linear_map R f) : M →ₗ M₂ := ⟨f, H.1, H.2⟩

@[simp] theorem mk'_apply {f : M → M₂} (H : is_linear_map R f) (x : M) :
  mk' f H x = f x := rfl

lemma is_linear_map_smul {R M : Type*} [comm_semiring R] [add_comm_monoid M] [semimodule R M] (c : R) :
  is_linear_map R (λ (z : M), c • z) :=
begin
  refine is_linear_map.mk (smul_add c) _,
  intros _ _,
  simp only [smul_smul, mul_comm]
end

--TODO: move
lemma is_linear_map_smul' {R M : Type*} [semiring R] [add_comm_monoid M] [semimodule R M] (a : M) :
  is_linear_map R (λ (c : R), c • a) :=
is_linear_map.mk (λ x y, add_smul x y a) (λ x y, mul_smul x y a)

variables {f : M → M₂} (lin : is_linear_map R f)
include M M₂ lin

lemma map_zero : f (0 : M) = (0 : M₂) := (lin.mk' f).map_zero

end add_comm_monoid

section add_comm_group

variables [semiring R] [add_comm_group M] [add_comm_group M₂]
variables [semimodule R M] [semimodule R M₂]
include R

lemma is_linear_map_neg :
  is_linear_map R (λ (z : M), -z) :=
is_linear_map.mk neg_add (λ x y, (smul_neg x y).symm)

variables {f : M → M₂} (lin : is_linear_map R f)
include M M₂ lin

lemma map_neg (x : M) : f (- x) = - f x := (lin.mk' f).map_neg x

lemma map_sub (x y) : f (x - y) = f x - f y := (lin.mk' f).map_sub x y

end add_comm_group

end is_linear_map

/-- Ring of linear endomorphismsms of a module. -/
abbreviation module.End (R : Type u) (M : Type v)
  [semiring R] [add_comm_monoid M] [semimodule R M] := M →ₗ[R] M

/-- Reinterpret an additive homomorphism as a `ℤ`-linear map. -/
def add_monoid_hom.to_int_linear_map [add_comm_group M] [add_comm_group M₂] (f : M →+ M₂) :
  M →ₗ[ℤ] M₂ :=
⟨f, f.map_add, f.map_int_module_smul⟩

/-- Reinterpret an additive homomorphism as a `ℚ`-linear map. -/
def add_monoid_hom.to_rat_linear_map [add_comm_group M] [vector_space ℚ M]
  [add_comm_group M₂] [vector_space ℚ M₂] (f : M →+ M₂) :
  M →ₗ[ℚ] M₂ :=
⟨f, f.map_add, f.map_rat_module_smul⟩

/-! ### Linear equivalences -/
section
set_option old_structure_cmd true

/-- A linear equivalence is an invertible linear map. -/
@[nolint has_inhabited_instance]
structure linear_equiv (R : Type u) (M : Type v) (M₂ : Type w)
  [semiring R] [add_comm_monoid M] [add_comm_monoid M₂] [semimodule R M] [semimodule R M₂]
  extends M →ₗ[R] M₂, M ≃ M₂
end

attribute [nolint doc_blame] linear_equiv.to_linear_map
attribute [nolint doc_blame] linear_equiv.to_equiv

infix ` ≃ₗ `:25 := linear_equiv _
notation M ` ≃ₗ[`:50 R `] ` M₂ := linear_equiv R M M₂

namespace linear_equiv

section add_comm_monoid

variables {M₄ : Type*}
variables [semiring R]
variables [add_comm_monoid M] [add_comm_monoid M₂] [add_comm_monoid M₃] [add_comm_monoid M₄]

section
variables [semimodule R M] [semimodule R M₂] [semimodule R M₃]
include R

instance : has_coe (M ≃ₗ[R] M₂) (M →ₗ[R] M₂) := ⟨to_linear_map⟩
-- see Note [function coercion]
instance : has_coe_to_fun (M ≃ₗ[R] M₂) := ⟨_, λ f, f.to_fun⟩

@[simp] lemma mk_apply {to_fun inv_fun map_add map_smul left_inv right_inv  a} :
  (⟨to_fun, map_add, map_smul, inv_fun, left_inv, right_inv⟩ : M ≃ₗ[R] M₂) a = to_fun a :=
rfl

lemma to_equiv_injective : function.injective (to_equiv : (M ≃ₗ[R] M₂) → M ≃ M₂) :=
λ ⟨_, _, _, _, _, _⟩ ⟨_, _, _, _, _, _⟩ h, linear_equiv.mk.inj_eq.mpr (equiv.mk.inj h)

end

section
variables {semimodule_M : semimodule R M} {semimodule_M₂ : semimodule R M₂}
variables (e e' : M ≃ₗ[R] M₂)

@[simp, norm_cast] theorem coe_coe : ((e : M →ₗ[R] M₂) : M → M₂) = (e : M → M₂) := rfl

@[simp] lemma coe_to_equiv : ((e.to_equiv) : M → M₂) = (e : M → M₂) := rfl

@[simp] lemma to_fun_apply {m : M} : e.to_fun m = e m := rfl

section
variables {e e'}
@[ext] lemma ext (h : ∀ x, e x = e' x) : e = e' :=
to_equiv_injective (equiv.ext h)

variables [semimodule R M] [semimodule R M₂]

lemma eq_of_linear_map_eq {f f' : M ≃ₗ[R] M₂} (h : (f : M →ₗ[R] M₂) = f') : f = f' :=
begin
  ext x,
  change (f : M →ₗ[R] M₂) x = (f' : M →ₗ[R] M₂) x,
  rw h
end

end

section
variables (M R)

/-- The identity map is a linear equivalence. -/
@[refl]
def refl [semimodule R M] : M ≃ₗ[R] M := { .. linear_map.id, .. equiv.refl M }
end

@[simp] lemma refl_apply [semimodule R M] (x : M) : refl R M x = x := rfl

/-- Linear equivalences are symmetric. -/
@[symm]
def symm : M₂ ≃ₗ[R] M :=
{ .. e.to_linear_map.inverse e.inv_fun e.left_inv e.right_inv,
  .. e.to_equiv.symm }

@[simp] lemma inv_fun_apply {m : M₂} : e.inv_fun m = e.symm m := rfl

variables {semimodule_M₃ : semimodule R M₃} (e₁ : M ≃ₗ[R] M₂) (e₂ : M₂ ≃ₗ[R] M₃)

/-- Linear equivalences are transitive. -/
@[trans]
def trans : M ≃ₗ[R] M₃ :=
{ .. e₂.to_linear_map.comp e₁.to_linear_map,
  .. e₁.to_equiv.trans e₂.to_equiv }

/-- A linear equivalence is an additive equivalence. -/
def to_add_equiv : M ≃+ M₂ := { .. e }

@[simp] lemma coe_to_add_equiv : ⇑(e.to_add_equiv) = e := rfl

@[simp] theorem trans_apply (c : M) :
  (e₁.trans e₂) c = e₂ (e₁ c) := rfl
@[simp] theorem apply_symm_apply (c : M₂) : e (e.symm c) = c := e.6 c
@[simp] theorem symm_apply_apply (b : M) : e.symm (e b) = b := e.5 b
@[simp] lemma symm_trans_apply (c : M₃) : (e₁.trans e₂).symm c = e₁.symm (e₂.symm c) := rfl

@[simp] lemma trans_refl : e.trans (refl R M₂) = e := to_equiv_injective e.to_equiv.trans_refl
@[simp] lemma refl_trans : (refl R M).trans e = e := to_equiv_injective e.to_equiv.refl_trans

lemma symm_apply_eq {x y} : e.symm x = y ↔ x = e y := e.to_equiv.symm_apply_eq

lemma eq_symm_apply {x y} : y = e.symm x ↔ e y = x := e.to_equiv.eq_symm_apply

@[simp] lemma trans_symm [semimodule R M] [semimodule R M₂] (f : M ≃ₗ[R] M₂) :
  f.trans f.symm = linear_equiv.refl R M :=
by { ext x, simp }

@[simp] lemma symm_trans [semimodule R M] [semimodule R M₂] (f : M ≃ₗ[R] M₂) :
  f.symm.trans f = linear_equiv.refl R M₂ :=
by { ext x, simp }

@[simp, norm_cast] lemma refl_to_linear_map [semimodule R M] :
  (linear_equiv.refl R M : M →ₗ[R] M) = linear_map.id :=
rfl

@[simp, norm_cast]
lemma comp_coe [semimodule R M] [semimodule R M₂] [semimodule R M₃] (f :  M ≃ₗ[R] M₂)
  (f' :  M₂ ≃ₗ[R] M₃) : (f' : M₂ →ₗ[R] M₃).comp (f : M →ₗ[R] M₂) = (f.trans f' : M →ₗ[R] M₃) :=
rfl

@[simp] theorem map_add (a b : M) : e (a + b) = e a + e b := e.map_add' a b
@[simp] theorem map_zero : e 0 = 0 := e.to_linear_map.map_zero
@[simp] theorem map_smul (c : R) (x : M) : e (c • x) = c • e x := e.map_smul' c x

@[simp] lemma map_sum {s : finset ι} (u : ι → M) : e (∑ i in s, u i) = ∑ i in s, e (u i) :=
e.to_linear_map.map_sum

@[simp] theorem map_eq_zero_iff {x : M} : e x = 0 ↔ x = 0 :=
e.to_add_equiv.map_eq_zero_iff
theorem map_ne_zero_iff {x : M} : e x ≠ 0 ↔ x ≠ 0 :=
e.to_add_equiv.map_ne_zero_iff

@[simp] theorem symm_symm : e.symm.symm = e := by { cases e, refl }

protected lemma bijective : function.bijective e := e.to_equiv.bijective
protected lemma injective : function.injective e := e.to_equiv.injective
protected lemma surjective : function.surjective e := e.to_equiv.surjective
protected lemma image_eq_preimage (s : set M) : e '' s = e.symm ⁻¹' s :=
e.to_equiv.image_eq_preimage s

end

end add_comm_monoid

end linear_equiv