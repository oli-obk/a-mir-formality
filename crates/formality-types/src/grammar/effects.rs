use std::sync::Arc;

use formality_core::{term, DowncastTo, Upcast, UpcastFrom};

use super::{Parameter, Variable};

#[term]
#[derive(Copy)]
pub enum EffectKind {
    Const,
    NoPanic,
}

#[term]
#[cast]
#[customize(constructors)] // FIXME: figure out upcasts with arc or special-case
pub struct Effect {
    data: Arc<EffectData>,
}

impl Effect {
    pub fn data(&self) -> &EffectData {
        &self.data
    }

    pub fn new(data: impl Upcast<EffectData>) -> Self {
        Self {
            data: Arc::new(data.upcast()),
        }
    }

    pub fn as_variable(&self) -> Option<Variable> {
        match self.data() {
            EffectData::Always(_) => None,
            EffectData::Variable(var) => Some(*var),
        }
    }

    pub fn as_value(&self) -> Option<EffectKind> {
        match self.data() {
            EffectData::Always(v) => Some(v.clone()),
            EffectData::Variable(_) => None,
        }
    }
}

#[term]
#[customize(parse)]
pub enum EffectData {
    Always(EffectKind),

    #[variable]
    Variable(Variable),
}

impl UpcastFrom<Effect> for Parameter {
    fn upcast_from(term: Effect) -> Self {
        Self::Effect(term)
    }
}

impl DowncastTo<Effect> for Parameter {
    fn downcast_to(&self) -> Option<Effect> {
        match self {
            Parameter::Const(_) | Parameter::Ty(_) | Parameter::Lt(_) => None,
            Parameter::Effect(c) => Some(c.clone()),
        }
    }
}

impl DowncastTo<EffectData> for Effect {
    fn downcast_to(&self) -> Option<EffectData> {
        Some(self.data().clone())
    }
}

impl DowncastTo<EffectData> for Parameter {
    fn downcast_to(&self) -> Option<EffectData> {
        let c: Effect = self.downcast_to()?;
        c.downcast_to()
    }
}

impl UpcastFrom<EffectKind> for EffectData {
    fn upcast_from(term: EffectKind) -> Self {
        EffectData::Always(term)
    }
}
